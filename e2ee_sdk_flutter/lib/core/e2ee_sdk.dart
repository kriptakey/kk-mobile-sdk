import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:e2ee_sdk_flutter/core/error_code.dart';
import 'package:flutter/services.dart';
import 'package:kms_e2ee_package/src/kk/structure.dart';
import 'package:pointycastle/export.dart';

import 'package:e2ee_sdk_flutter/core/constants.dart';
import 'package:e2ee_sdk_flutter/core/utility.dart';
import 'package:e2ee_sdk_flutter/core/crypto.dart';
import 'package:e2ee_sdk_flutter/core/exceptions.dart';

// NOTE: Private method
Future<Uint8List> _generateHMACSHA512(
    Uint8List message, Uint8List macKey) async {
  try {
    final crypto.Mac mac = await crypto.Hmac.sha512()
        .calculateMac(message, secretKey: crypto.SecretKey(macKey));
    return Uint8List.fromList(mac.bytes);
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Generate HMAC with SHA-512 failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.HMAC_SHA512_GENERATION_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_GENERATE_HMAC_SHA_512, null, null);
  }
}

class E2eeSdk {
  Future<String> generateRandomString(int length) async {
    try {
      final Random random = Random.secure();
      return String.fromCharCodes(
          List.generate(length, (index) => random.nextInt(33) + 89));
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Generate random string failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.RANDOM_STRING_GENERATION_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_GENERATE_RANDOM_STRING,
          null,
          null);
    }
  }

  Future<String> getRSAPublicKeyPemFromCertificate(String certificate) async {
    try {
      final X509CertificateData x509CertificateData =
          X509Utils.x509CertificateFromPem(certificate);
      final String publicKeyBytes =
          (x509CertificateData.tbsCertificate?.subjectPublicKeyInfo.bytes)!;
      final Uint8List decodedPublicKeyBytes =
          Uint8List.fromList(hex.decode(publicKeyBytes));
      final rsaPublicKeyObject =
          CryptoUtils.rsaPublicKeyFromDERBytes(decodedPublicKeyBytes);
      return CryptoUtils.encodeRSAPublicKeyToPem(rsaPublicKeyObject);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Invalid PEM certificate format.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.INVALID_PEM_CERTIFICATE_FORMAT,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_GET_RSA_PUBLIC_KEY_PEM_FROM_CERTIFICATE,
          null,
          null);
    }
  }

  Future<Uint8List> encryptRSA(String rsaPublicKeyPem, Uint8List data,
      [Uint8List? oaepLabel]) async {
    try {
      final RSAPublicKey rsaPublicKey =
          CryptoUtils.rsaPublicKeyFromPem(rsaPublicKeyPem);
      // Initializing Cipher
      final OAEPEncoding cipher = OAEPEncoding.withCustomDigest(
          () => SHA512Digest(), RSAEngine(), oaepLabel);
      cipher.init(true, PublicKeyParameter<RSAPublicKey>(rsaPublicKey));

      // Process the encryption
      return cipher.process(data);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Encrypt RSA failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.RSA_ENCRYPTION_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_ENCRYPT_RSA,
          null,
          null);
    }
  }

  Future<bool> verifyRSASignature(String rsaPublicKeyPem,
      Uint8List messageBytes, Uint8List signatureBytes) async {
    try {
      final RSAPublicKey rsaPublicKey =
          CryptoUtils.rsaPublicKeyFromPem(rsaPublicKeyPem);
      final Signer signer = Signer(RSA_SHA_512);
      signer.init(false, PublicKeyParameter<RSAPublicKey>(rsaPublicKey));
      return signer.verifySignature(messageBytes, RSASignature(signatureBytes));
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Invalid PEM public key or signature format.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.INVALID_PEM_PUBLIC_KEY_OR_SIGNATURE_FORMAT,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_VERIFY_RSA_SIGNATURE,
          null,
          null);
    }
  }

  Future<Uint8List> generateRandomBytes(int length) async {
    try {
      final Random random = Random.secure();
      return Uint8List.fromList(List<int>.generate(
          length, (i) => random.nextInt(MAXIMUM_RANDOM_BITS)));
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Invalid random length.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.INVALID_RANDOM_LENGTH,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_GENERATE_RANDOM_BYTES,
          null,
          null);
    }
  }

  Future<ResponseE2eeEncrypt> e2eeEncrypt(RequestE2eeEncrypt request) async {
    try {
      List<String> encryptedDataBlockList = [];

      // Generate some keys
      final Future<Uint8List> sessionKey =
          generateRandomBytes(AES_256_KEY_LENGTH);
      final Future<Uint8List> macKey = generateRandomBytes(AES_256_KEY_LENGTH);

      // Concat the previous keys
      final Uint8List transportKey =
          serializeListOfUint8Lists([await sessionKey, await macKey]);
      final Future<Uint8List> wrappedTransportKey = encryptRSA(
          request.publicKeyPem,
          transportKey,
          Uint8List.fromList(utf8.encode(request.oaepLabel!)));
      List<Uint8List> wrappedTransportKeyAndEncryptedDataList = [];

      List<Future<EncryptedData>> encryptedMessages = [];
      for (final message in request.messages) {
        // Generate random IV for each messages
        final Future<Uint8List> iv = generateRandomBytes(GCM_IV_LENGTH);

        // Decode the client data to bytes
        encryptedMessages
            .add(encryptAES256GCM(message, await sessionKey, await iv, null));
      }

      for (final message in encryptedMessages) {
        final EncryptedData encryptedData = await message;

        // Convert int to Uint8List
        final Uint8List encryptedDataLengthBytes =
            intToUint8List(encryptedData.ciphertext.length);

        // Sequence: tag, iv, ciphertext length, ciphertext
        final Uint8List encryptedDataBlock = serializeListOfUint8Lists([
          encryptedData.tag,
          encryptedData.iv,
          encryptedDataLengthBytes,
          encryptedData.ciphertext
        ]);

        wrappedTransportKeyAndEncryptedDataList.add(encryptedDataBlock);
        encryptedDataBlockList.add(base64Encode(encryptedDataBlock));
      }

      wrappedTransportKeyAndEncryptedDataList.insert(
          0, await wrappedTransportKey);

      // Serialize wrapped client key and the encrypted data block
      final Uint8List serializedWrappedKeyAndEncryptedDataList =
          serializeListOfUint8Lists(wrappedTransportKeyAndEncryptedDataList);

      // Calculate HMAC of serializedWrappedKeyAndEncryptedDataList
      final Future<Uint8List> hashValue = _generateHMACSHA512(
          serializedWrappedKeyAndEncryptedDataList, await macKey);

      final Uint8List serializedMetadata = serializeListOfUint8Lists(
          [await hashValue, await wrappedTransportKey]);

      return ResponseE2eeEncrypt(
          base64Encode(serializedMetadata), encryptedDataBlockList);
    } on KKException catch (ex) {
      throw KKException(ex.message!, ex.code, ex.details, ex.stacktrace);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Encrypt RSA failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.E2EE_ENCRYPT_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_E2EE_ENCRYPT,
          null,
          null);
    }
  }

  Future<bool> verifyCertificateSignature(String certificateChain) async {
    try {
      final List<X509CertificateData> x509CertificateDataList =
          X509Utils.parseChainString(certificateChain);
      return X509Utils.checkChain(x509CertificateDataList).isValid();
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Invalid certificate chain format.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.INVALID_CERTIFICATE_CHAIN_FORMAT,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_VERIFY_CERTIFICATE_SIGNATURE,
          null,
          null);
    }
  }

  Future<Uint8List> calculateDigest(
      Uint8List dataToDigest, String hashAlgo) async {
    Uint8List? digestResult;
    switch (hashAlgo) {
      case "SHA-256":
        try {
          final digest = SHA256Digest();
          digestResult = digest.process(dataToDigest);
        } on PlatformException catch (e) {
          throw KKException(
              "Error: Digest generation failed.\r\nStack trace: ${e.stacktrace}",
              ErrorCode.DIGEST_GENERATION_FAILED,
              e.details,
              e.stacktrace);
        } catch (e, s) {
          throw KKException(
              "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
              ErrorCode.ERROR_IN_FUNCTION_CALCULATE_DIGEST,
              null,
              null);
        }
      case "SHA-384":
        try {
          final digest = SHA384Digest();
          digestResult = digest.process(dataToDigest);
        } on PlatformException catch (e) {
          throw KKException(
              "Error: Digest generation failed.\r\nStack trace: ${e.stacktrace}",
              ErrorCode.DIGEST_GENERATION_FAILED,
              e.details,
              e.stacktrace);
        } catch (e, s) {
          throw KKException(
              "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
              ErrorCode.ERROR_IN_FUNCTION_CALCULATE_DIGEST,
              null,
              null);
        }
      case "SHA-512":
        try {
          final digest = SHA512Digest();
          digestResult = digest.process(dataToDigest);
        } on PlatformException catch (e) {
          throw KKException(
              "Error: Digest generation failed.\r\nStack trace: ${e.stacktrace}",
              ErrorCode.DIGEST_GENERATION_FAILED,
              e.details,
              e.stacktrace);
        } catch (e, s) {
          throw KKException(
              "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
              ErrorCode.ERROR_IN_FUNCTION_CALCULATE_DIGEST,
              null,
              null);
        }
      default:
        digestResult = null;
    }
    return digestResult!;
  }
}
