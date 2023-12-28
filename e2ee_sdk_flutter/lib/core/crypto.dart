import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';

import 'package:kms_e2ee_package/src/kk/structure.dart';
import 'package:e2ee_sdk_flutter/core/constants.dart';
import 'package:e2ee_sdk_flutter/core/utility.dart';

Future<Uint8List> _generateHMACSHA512(
    Uint8List message, Uint8List macKey) async {
  final crypto.Mac mac = await crypto.Hmac.sha512()
      .calculateMac(message, secretKey: crypto.SecretKey(macKey));
  return Uint8List.fromList(mac.bytes);
}

Future<EncryptedData> encryptAES256GCM(Uint8List message,
    Uint8List secretKeyBytes, Uint8List iv, Uint8List? aad) async {
  final crypto.SecretBox secretBox = await crypto.AesGcm.with256bits().encrypt(
      message,
      secretKey: crypto.SecretKey(secretKeyBytes),
      nonce: iv,
      aad: aad ?? Uint8List(0));

  return EncryptedData(iv, Uint8List.fromList(secretBox.mac.bytes),
      Uint8List.fromList(secretBox.cipherText));
}

String generateRandomString(int length) {
  final Random random = Random.secure();
  return String.fromCharCodes(
      List.generate(length, (index) => random.nextInt(33) + 89));
}

String getRSAPublicKeyPemFromCertificate(String certificate) {
  final X509CertificateData x509CertificateData =
      X509Utils.x509CertificateFromPem(certificate);
  final String publicKeyBytes =
      (x509CertificateData.tbsCertificate?.subjectPublicKeyInfo.bytes)!;
  final Uint8List decodedPublicKeyBytes =
      Uint8List.fromList(hex.decode(publicKeyBytes));
  final rsaPublicKeyObject =
      CryptoUtils.rsaPublicKeyFromDERBytes(decodedPublicKeyBytes);
  return CryptoUtils.encodeRSAPublicKeyToPem(rsaPublicKeyObject);
}

Uint8List encryptRSA(String rsaPublicKeyPem, Uint8List data,
    [Uint8List? oaepLabel]) {
  final RSAPublicKey rsaPublicKey =
      CryptoUtils.rsaPublicKeyFromPem(rsaPublicKeyPem);
  // Initializing Cipher
  final OAEPEncoding cipher = OAEPEncoding.withCustomDigest(
      () => SHA512Digest(), RSAEngine(), oaepLabel);
  cipher.init(true, PublicKeyParameter<RSAPublicKey>(rsaPublicKey));

  // Process the encryption
  return cipher.process(data);
}

bool verifyRSASignature(
    String rsaPublicKeyPem, Uint8List messageBytes, Uint8List signatureBytes) {
  final RSAPublicKey rsaPublicKey =
      CryptoUtils.rsaPublicKeyFromPem(rsaPublicKeyPem);
  final Signer signer = Signer(RSA_SHA_512);
  signer.init(false, PublicKeyParameter<RSAPublicKey>(rsaPublicKey));
  return signer.verifySignature(messageBytes, RSASignature(signatureBytes));
}

Uint8List generateRandomBytes(int length) {
  final Random random = Random.secure();
  return Uint8List.fromList(
      List<int>.generate(length, (i) => random.nextInt(MAXIMUM_RANDOM_BITS)));
}

Future<ResponseE2eeEncrypt> e2eeEncrypt(RequestE2eeEncrypt request) async {
  List<String> encryptedDataBlockList = [];

  // Generate some keys
  final Uint8List sessionKey = generateRandomBytes(AES_256_KEY_LENGTH);
  final Uint8List macKey = generateRandomBytes(AES_256_KEY_LENGTH);

  // Concat the previous keys
  final Uint8List transportKey =
      serializeListOfUint8Lists([sessionKey, macKey]);
  final Uint8List wrappedTransportKey = encryptRSA(request.publicKeyPem,
      transportKey, Uint8List.fromList(utf8.encode(request.oaepLabel!)));
  List<Uint8List> wrappedTransportKeyAndEncryptedDataList = [];

  List<Future<EncryptedData>> encryptedMessages = [];
  for (final message in request.messages) {
    // Generate random IV for each messages
    final Uint8List iv = generateRandomBytes(GCM_IV_LENGTH);

    // Decode the client data to bytes
    encryptedMessages.add(encryptAES256GCM(message, sessionKey, iv, null));
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

  wrappedTransportKeyAndEncryptedDataList.insert(0, wrappedTransportKey);

  // Serialize wrapped client key and the encrypted data block
  final Uint8List serializedWrappedKeyAndEncryptedDataList =
      serializeListOfUint8Lists(wrappedTransportKeyAndEncryptedDataList);

  // Calculate HMAC of serializedWrappedKeyAndEncryptedDataList
  final Future<Uint8List> hashValue =
      _generateHMACSHA512(serializedWrappedKeyAndEncryptedDataList, macKey);

  final Uint8List serializedMetadata =
      serializeListOfUint8Lists([await hashValue, wrappedTransportKey]);

  return ResponseE2eeEncrypt(
      base64Encode(serializedMetadata), encryptedDataBlockList);
}

bool verifyCertificateSignature(String certificateChain) {
  final List<X509CertificateData> x509CertificateDataList =
      X509Utils.parseChainString(certificateChain);
  return X509Utils.checkChain(x509CertificateDataList).isValid();
}

Uint8List calculateDigest(Uint8List dataToDigest, String hashAlgo) {
  Uint8List? digestResult;
  switch (hashAlgo) {
    case "SHA-256":
      final digest = SHA256Digest();
      digestResult = digest.process(dataToDigest);

    case "SHA-384":
      final digest = SHA384Digest();
      digestResult = digest.process(dataToDigest);
    case "SHA-512":
      final digest = SHA512Digest();
      digestResult = digest.process(dataToDigest);
    default:
      digestResult = null;
  }
  return digestResult!;
}
