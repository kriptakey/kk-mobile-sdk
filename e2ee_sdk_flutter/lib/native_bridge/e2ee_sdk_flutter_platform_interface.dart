import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'e2ee_sdk_flutter_method_channel.dart';

import 'package:kms_e2ee_package/api.dart';

abstract class E2eeSdkFlutterPlatform extends PlatformInterface {
  /// Constructs a E2eeSdkFlutterPlatform.
  E2eeSdkFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static E2eeSdkFlutterPlatform _instance = MethodChannelE2eeSdkFlutter();

  /// The default instance of [E2eeSdkFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelE2eeSdkFlutter].
  static E2eeSdkFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [E2eeSdkFlutterPlatform] when
  /// they register themselves.
  static set instance(E2eeSdkFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool?> isSecureEnvironmentAvailable() {
    throw UnimplementedError(
        'isSecureEnvironmentAvailable() has not been implemented.');
  }

  Future<bool?> isStrongBoxAvailable() {
    throw UnimplementedError(
        'isStrongBoxAvailable() has not been implemented.');
  }

  Future<String?> generateApplicationCSR(
      String keyAlias, DistinguishedName distinguishedName) {
    throw UnimplementedError(
        'generateApplicationCSR() has not been implemented.');
  }

  Future<Uint8List?> aesEncrypt(
      String keyAlias, Uint8List plainData, Uint8List iv, Uint8List? aad) {
    throw UnimplementedError('aesEncrypt() has not been implemented.');
  }

  Future<Uint8List?> aesDecrypt(String keyAlias, Uint8List cipherData,
      Uint8List tag, Uint8List iv, Uint8List? aad) {
    throw UnimplementedError('aesDecrypt() has not been implemented.');
  }

  Future<Uint8List?> rsaDecrypt(String keyAlias, Uint8List cipherData,
      [Uint8List? oaepLabel]) {
    throw UnimplementedError('rsaDecrypt() has not been implemented.');
  }

  Future<Uint8List?> generateSignature(String keyAlias, Uint8List plainData) {
    throw UnimplementedError('generateSignature() has not been implemented.');
  }

  Future<void> generateAES256Key(String keyAlias,
      [bool requireAuth = true, bool allowOverwrite = false]) {
    throw UnimplementedError('generateAES256Key() has not been implemented.');
  }

  Future<void> generateECP256Keypair(String keyAlias,
      [bool requireAuth = true, bool allowOverwrite = false]) {
    throw UnimplementedError(
        'generateECP256Keypair() has not been implemented.');
  }

  Future<void> generateRSAKeypair(String keyAlias, int keySize,
      [bool requireAuth = true, bool allowOverwrite = false]) {
    throw UnimplementedError('generateRSAKeypair() has not been implemented.');
  }

  Future<void> importAES256GCMKey(
      String wrappingKeyAlias, String importedKeyAlias, Uint8List wrappedKey,
      [bool allowOverwrite = false]) {
    throw UnimplementedError('importAES256GCMKey() has not been implemented.');
  }

  Future<String?> getPublicKeyPEM(String keyAlias) async {
    throw UnimplementedError('getPublicKeyPEM() has not been implemented.');
  }

  Future<Uint8List?> generateDigestSignature(String keyAlias, Uint8List digest) {
    throw UnimplementedError('generateDigestSignature() has not been implemented.');
  }

  Future<void> deleteAES256GCMKey(String keyAlias) {
    throw UnimplementedError('deleteAES256GCMKey() has not been implemented.');
  }

  Future<void> deleteKeyPair(String keyAlias) {
    throw UnimplementedError('deleteKeyPair() has not been implemented.');
  }
}
