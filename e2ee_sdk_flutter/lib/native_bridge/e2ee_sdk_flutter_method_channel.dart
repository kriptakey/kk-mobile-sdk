import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'e2ee_sdk_flutter_platform_interface.dart';

import 'package:kms_e2ee_package/api.dart';

/// An implementation of [E2eeSdkFlutterPlatform] that uses method channels.
class MethodChannelE2eeSdkFlutter extends E2eeSdkFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('e2ee_sdk_flutter');

  @override
  Future<bool?> isSecureEnvironmentAvailable() {
    return methodChannel.invokeMethod<bool>('isSecureEnvironmentAvailable');
  }

  @override
  Future<bool?> isStrongBoxAvailable() {
    return methodChannel.invokeMethod<bool>('isStrongBoxAvailable');
  }

  @override
  Future<String?> generateApplicationCSR(
      String keyAlias, DistinguishedName distinguishedName) {
    return methodChannel
        .invokeMethod<String>('generateApplicationCSR', <String, dynamic>{
      'keyAlias': keyAlias,
      'commonName': distinguishedName.commonName,
      'country': distinguishedName.country,
      'location': distinguishedName.location,
      'state': distinguishedName.state,
      'organizationName': distinguishedName.organizationName,
      'organizationUnit': distinguishedName.organizationUnit,
    });
  }

  @override
  Future<Uint8List?> aesEncrypt(
      String keyAlias, Uint8List plainData, Uint8List iv, Uint8List? aad) {
    return methodChannel
        .invokeMethod<Uint8List>('encryptAES256GCM', <String, dynamic>{
      'keyAlias': keyAlias,
      'plainData': plainData,
      'iv': iv,
      'aad': aad,
    });
  }

  @override
  Future<Uint8List?> aesDecrypt(String keyAlias, Uint8List cipherData,
      Uint8List tag, Uint8List iv, Uint8List? aad) {
    return methodChannel
        .invokeMethod<Uint8List>('decryptAES256GCM', <String, dynamic>{
      'keyAlias': keyAlias,
      'cipherData': cipherData,
      'tag': tag,
      'iv': iv,
      'aad': aad,
    });
  }

  @override
  Future<Uint8List?> rsaDecrypt(String keyAlias, Uint8List cipherData,
      [Uint8List? oaepLabel]) {
    return methodChannel
        .invokeMethod<Uint8List>('decryptRSA', <String, dynamic>{
      'keyAlias': keyAlias,
      'cipherData': cipherData,
      'oaepLabel': oaepLabel,
    });
  }

  @override
  Future<Uint8List?> generateSignature(String keyAlias, Uint8List plainData) {
    return methodChannel.invokeMethod<Uint8List>('signData', <String, dynamic>{
      'keyAlias': keyAlias,
      'plainData': plainData,
    });
  }

  @override
  Future<void> generateAES256Key(String keyAlias,
      [bool requireAuth = true, bool allowOverwrite = false]) {
    return methodChannel
        .invokeMethod<void>('generateAES256Key', <String, dynamic>{
      'keyAlias': keyAlias,
      'requireAuth': requireAuth,
      'allowOverwrite': allowOverwrite,
    });
  }

  @override
  Future<void> generateECP256Keypair(String keyAlias,
      [bool requireAuth = true, bool allowOverwrite = false]) {
    return methodChannel
        .invokeMethod<void>('generateECP256Keypair', <String, dynamic>{
      'keyAlias': keyAlias,
      'requireAuth': requireAuth,
      'allowOverwrite': allowOverwrite,
    });
  }

  @override
  Future<void> generateRSAKeypair(String keyAlias, int keySize,
      [bool requireAuth = true, bool allowOverwrite = false]) {
    return methodChannel
        .invokeMethod<void>('generateRSAKeypair', <String, dynamic>{
      'keyAlias': keyAlias,
      'keySize': keySize,
      'requireAuth': requireAuth,
      'allowOverwrite': allowOverwrite,
    });
  }

  @override
  Future<void> importAES256GCMKey(
      String wrappingKeyAlias, String importedKeyAlias, Uint8List wrappedKey,
      [bool allowOverwrite = false]) {
    return methodChannel
        .invokeMethod<void>('importAES256GCMKey', <String, dynamic>{
      'wrappingKeyAlias': wrappingKeyAlias,
      'importedKeyAlias': importedKeyAlias,
      'wrappedKey': wrappedKey,
      'allowOverwrite': allowOverwrite,
    });
  }

  @override
  Future<String?> getPublicKeyPEM(String keyAlias) {
    return methodChannel
        .invokeMethod<String>('getPublicKeyPEM', <String, dynamic>{
      'keyAlias': keyAlias,
    });
  }

  @override
  Future<Uint8List?> generateDigestSignature(String keyAlias, Uint8List digest) {
    return methodChannel.invokeMethod<Uint8List>('signDigest', <String, dynamic>{
      'keyAlias': keyAlias,
      'digest': digest,
    });
  }

  @override
  Future<void> deleteAES256GCMKey(String keyAlias) {
    return methodChannel.invokeMethod<void>('deleteAES256GCMKey', <String, dynamic>{
      'keyAlias': keyAlias
    });
  }

  @override
  Future<void> deleteKeyPair(String keyAlias) {
    return methodChannel.invokeMethod<void>('deleteKeyPair', <String, dynamic>{
      'keyAlias': keyAlias
    });
  }
}
