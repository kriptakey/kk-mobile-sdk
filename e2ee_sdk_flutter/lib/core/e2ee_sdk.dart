import 'dart:async';
import 'dart:typed_data';

import 'package:e2ee_sdk_flutter/core/error_code.dart';
import 'package:flutter/services.dart';

import 'package:kms_e2ee_package/src/kk/structure.dart';
import 'package:e2ee_sdk_flutter/core/crypto.dart' as kkcrypto;
import 'package:e2ee_sdk_flutter/core/exceptions.dart';

class E2eeSdk {
  String generateRandomString(int length) {
    try {
      return kkcrypto.generateRandomString(length);
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

  String getRSAPublicKeyPemFromCertificate(String certificate) {
    try {
      return kkcrypto.getRSAPublicKeyPemFromCertificate(certificate);
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

  Uint8List encryptRSA(String rsaPublicKeyPem, Uint8List data,
      [Uint8List? oaepLabel]) {
    try {
      return kkcrypto.encryptRSA(rsaPublicKeyPem, data);
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

  bool verifyRSASignature(String rsaPublicKeyPem, Uint8List messageBytes,
      Uint8List signatureBytes) {
    try {
      return kkcrypto.verifyRSASignature(
          rsaPublicKeyPem, messageBytes, signatureBytes);
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

  Uint8List generateRandomBytes(int length) {
    try {
      return kkcrypto.generateRandomBytes(length);
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
      return kkcrypto.e2eeEncrypt(request);
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

  bool verifyCertificateSignature(String certificateChain) {
    try {
      return kkcrypto.verifyCertificateSignature(certificateChain);
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

  Uint8List calculateDigest(Uint8List dataToDigest, String hashAlgo) {
    try {
      return kkcrypto.calculateDigest(dataToDigest, hashAlgo);
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
  }
}
