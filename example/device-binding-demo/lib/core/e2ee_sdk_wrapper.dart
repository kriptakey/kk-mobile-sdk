import 'dart:typed_data';
import 'dart:convert';

import 'package:kms_e2ee_package/api.dart';

class BackendServerAuth {
  static const int _nonceLength = 16;
  final Future<String> _nonce;
  final Future<String> _publicKey;

  BackendServerAuth(String pinnedCertPEM)
      : _nonce = E2eeSdkPackage().generateRandomString(_nonceLength),
        _publicKey =
            E2eeSdkPackage().getRSAPublicKeyPemFromCertificate(pinnedCertPEM);

  Future<String> getEncryptedNonce() async {
    try {
      final Uint8List encryptedNonce = await E2eeSdkPackage().encryptRSA(
          await _publicKey, Uint8List.fromList(utf8.encode(await _nonce)));
      return base64Encode(encryptedNonce);
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }
  }

  Future<bool> verifyNonceSignature(String encodedSignature) async {
    try {
      return E2eeSdkPackage().verifyRSASignature(
          await _publicKey,
          Uint8List.fromList(utf8.encode(await _nonce)),
          base64Decode(encodedSignature));
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }
  }
}

class PasswordlessDeviceRegistration {
  Future<bool> verify(
      String deviceCertificate, String pinnedCertificate) async {
    try {
      if ((await E2eeSdkPackage()
              .verifyCertificateSignature(deviceCertificate)) &&
          (await E2eeSdkPackage()
              .verifyCertificateSignature(pinnedCertificate))) {
        return true;
      }
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }
    return false;
  }
}
