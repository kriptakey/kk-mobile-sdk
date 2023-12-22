import 'dart:typed_data';
import 'dart:convert';

import 'package:e2ee_sdk_flutter/api.dart';

class BackendServerAuth {
  static const int _nonceLength = 16;
  final Future<String> _nonce;
  final Future<String> _publicKey;

  BackendServerAuth(String pinnedCertPEM)
      : _nonce = E2eeSdk().generateRandomString(_nonceLength),
        _publicKey =
            E2eeSdk().getRSAPublicKeyPemFromCertificate(pinnedCertPEM);

  Future<String> getEncryptedNonce() async {
    final Uint8List encryptedNonce = await E2eeSdk().encryptRSA(
        await _publicKey, Uint8List.fromList(utf8.encode(await _nonce)));
    return base64Encode(encryptedNonce);
  }

  Future<bool> verifyNonceSignature(String encodedSignature) async {
    return E2eeSdk().verifyRSASignature(
        await _publicKey,
        Uint8List.fromList(utf8.encode(await _nonce)),
        base64Decode(encodedSignature));
  }
}

class ResponseGetWrappedClientKey {
  String wrappedKey;
  String kmsKeyWrapped;

  ResponseGetWrappedClientKey(this.wrappedKey, this.kmsKeyWrapped);
}