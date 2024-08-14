import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';
import 'package:cryptography/cryptography.dart' as crypto;

import 'package:kms_e2ee_package/api.dart';
import 'package:e2ee_sdk_flutter/native_bridge/e2ee_sdk_flutter_platform_interface.dart';
import 'package:e2ee_sdk_flutter/core/constants.dart';
import 'package:e2ee_sdk_flutter/core/crypto.dart';
import 'package:e2ee_sdk_flutter/core/exceptions.dart';
import 'package:e2ee_sdk_flutter/core/utility.dart';
import 'package:e2ee_sdk_flutter/core/e2ee_sdk.dart';
import 'package:e2ee_sdk_flutter/core/error_code.dart';

// NOTE: Private method
Future<Uint8List?> _getClientKeyFromSecureStorage(String keyAlias) async {
  try {
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();

    var encodedClientKey = await secureStorage.read(key: keyAlias);
    if (encodedClientKey != null) {
      return Uint8List.fromList(hex.decode(encodedClientKey));
    }
    return null;
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Get client key from secure storage failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.GET_CLIENT_KEY_FROM_SECURE_STORAGE_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException(
        "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_GET_CLIENT_KEY_FROM_SECURE_STORAGE,
        null,
        null);
  }
}

// NOTE: Private method
Future<EncryptedData> _aesEncrypt(
    String keyAlias, Uint8List plainData, Uint8List iv, Uint8List? aad,
    [bool deviceBinding = false]) async {
  if (Platform.isAndroid || deviceBinding) {
    try {
      final Uint8List? encryptedData = await E2eeSdkFlutterPlatform.instance
          .aesEncrypt(keyAlias, plainData, iv, aad);

      return EncryptedData(
          iv,
          Uint8List.sublistView(encryptedData!,
              encryptedData.length - TAG_LENGTH, encryptedData.length),
          Uint8List.sublistView(
              encryptedData, 0, encryptedData.length - TAG_LENGTH));
    } on PlatformException catch (e) {
      throw KKException(
          "Error: AES encryption failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.AES_256_GCM_ENCRYPTION_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_AES_ENCRYPT,
          null,
          null);
    }
  } else if (Platform.isIOS && !deviceBinding) {
    try {
      final clientKey = await _getClientKeyFromSecureStorage(keyAlias);
      return encryptAES256GCM(plainData, clientKey!, iv, aad);
    } on KKException catch (e) {
      throw KKException(e.message!, e.code, e.details, e.stacktrace);
    }
  } else {
    throw KKException("Error: Platform not supported.",
        ErrorCode.PLATFORM_NOT_SUPPORTED, null, null);
  }
}

// NOTE: Private method
SecureRandom _generateSecureRandom() {
  try {
    final SecureRandom secureRandom = FortunaRandom();
    final Random seedSource = Random.secure();

    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    return secureRandom;
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Generate secure random failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.GENERATE_SECURE_RANDOM_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_GENERATE_SECURE_RANDOM, null, null);
  }
}

// NOTE: Private method
AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateRSAKeypair(
    SecureRandom secureRandom, int bitLength) {
  try {
    final RSAKeyGenerator keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse(RSA_EXPONENT), bitLength, 64),
          secureRandom));

    final keyPair = keyGen.generateKeyPair();

    // Cast the generated key pair into the RSA key types
    final publicKey = keyPair.publicKey as RSAPublicKey;
    final privateKey = keyPair.privateKey as RSAPrivateKey;

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
        publicKey, privateKey);
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Generate RSA key pair failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.RSA_KEY_PAIR_GENERATION_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_GENERATE_RSA_KEY_PAIR, null, null);
  }
}

// NOTE: Private method
Future<void> _createRSAKeypairInFlutterSecureStorage(
    String keyAlias, FlutterSecureStorage secureStorage, int keySize) async {
  final SecureRandom secureRandom = _generateSecureRandom();

  try {
    final AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keyPair =
        _generateRSAKeypair(secureRandom, keySize);

    final String privateKeyPem =
        CryptoUtils.encodeRSAPrivateKeyToPem(keyPair.privateKey);
    final String publicKeyPem =
        CryptoUtils.encodeRSAPublicKeyToPem(keyPair.publicKey);

    // Serialize key pair object
    var jsonAsymmetricKeyPairObject =
        jsonEncode(AsymmetricKeyPairObject(publicKeyPem, privateKeyPem));

    // Store the key pair to secure storage
    await secureStorage.write(
        key: keyAlias, value: jsonAsymmetricKeyPairObject);
  } on KKException catch (e) {
    throw KKException(e.message!, e.code, e.details, e.stacktrace);
  } on PlatformException catch (e) {
    throw KKException(
        "Error: RSA key pair generation in secure storage failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.RSA_KEY_PAIR_GENERATION_IN_SECURE_STORAGE_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException(
        "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_CREATE_RSA_KEY_PAIR_IN_SECURE_STORAGE,
        null,
        null);
  }
}

// NOTE: Private method
Future<void> _generateRSAKeypairInSecureStorage(String keyAlias, int keySize,
    [bool requireAuth = true, bool allowOverwrite = false]) async {
  if (Platform.isAndroid) {
    try {
      return E2eeSdkFlutterPlatform.instance.generateRSAKeypair(keyAlias,
          keySize, requireAuth = requireAuth, allowOverwrite = allowOverwrite);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Generate RSA key pair in secure storage failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.RSA_KEY_PAIR_GENERATION_IN_SECURE_STORAGE_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_GENERATE_RSA_KEY_PAIR_IN_SECURE_STORAGE,
          null,
          null);
    }
  } else if (Platform.isIOS) {
    if (!requireAuth) {
      try {
        const FlutterSecureStorage storage = FlutterSecureStorage();
        var keyPairJson = await storage.read(key: keyAlias);
        if (keyPairJson != null && allowOverwrite) {
          await storage.delete(key: keyAlias);
        } else if (keyPairJson != null) {
          throw KKException("Key pair already exists!",
              ErrorCode.KEY_PAIR_ALREADY_EXISTS, null, null);
        }
        return _createRSAKeypairInFlutterSecureStorage(
            keyAlias, storage, keySize);
      } on KKException catch (e) {
        throw KKException(e.message!, e.code, e.details, e.stacktrace);
      } on PlatformException catch (e) {
        throw KKException(
            "Create rsa key pair in secure storage failed.",
            ErrorCode.RSA_KEY_PAIR_GENERATION_IN_SECURE_STORAGE_FAILED,
            e.details,
            e.stacktrace);
      } catch (e, s) {
        throw KKException(
            "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
            ErrorCode.ERROR_IN_FUNCTION_GENERATE_RSA_KEY_PAIR_IN_SECURE_STORAGE,
            null,
            null);
      }
    } else {
      // TODO: Generate Keypair in untrusted and store to Keychain with user authentication requirement
      // Call method from native iOS to assign the user authentication.
      // Currently, it is not needed yet.
    }
  }
}

// NOTE: Private method
Future<AsymmetricKeyPairObject?> _getKeyPairFromFlutterSecureStorage(
    String keyAlias) async {
  try {
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();

    // Retrieve key from secure storage
    var keyPairJson = await secureStorage.read(key: keyAlias);
    if (keyPairJson != null) {
      Map<String, dynamic> asymmetricKeyPairMap = jsonDecode(keyPairJson);
      var asymmetricKeyPairObject =
          AsymmetricKeyPairObject.fromJson(asymmetricKeyPairMap);
      return asymmetricKeyPairObject;
    } else {
      return null;
    }
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Get key pair from secure storage failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.KEY_NOT_FOUND,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException(
        "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_GET_KEYPAIR_FROM_FLUTTER_SECURE_STORAGE,
        null,
        null);
  }
}

// NOTE: Private method
Future<String?> _getPublicKeyPEM(String keyAlias) async {
  if (Platform.isAndroid) {
    try {
      return E2eeSdkFlutterPlatform.instance.getPublicKeyPEM(keyAlias);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Get public key PEM failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.KEY_NOT_FOUND,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_GET_PUBLIC_KEY_PEM,
          null,
          null);
    }
  } else if (Platform.isIOS) {
    try {
      final AsymmetricKeyPairObject? keyPairObject =
          await _getKeyPairFromFlutterSecureStorage(keyAlias);
      return keyPairObject!.publicKeyPem;
    } on KKException catch (e) {
      throw KKException(e.message!, e.code, e.details, e.stacktrace);
    }
  }
  return null;
}

// NOTE: Private method
Uint8List _decryptRSA(String rsaPrivateKeyPem, Uint8List message,
    [Uint8List? oaepLabel]) {
  try {
    final RSAPrivateKey rsaPrivateKey =
        CryptoUtils.rsaPrivateKeyFromPem(rsaPrivateKeyPem);
    // Initializing Cipher
    final OAEPEncoding cipher = OAEPEncoding.withCustomDigest(
        () => SHA256Digest(), RSAEngine(), oaepLabel);
    cipher.init(false, PrivateKeyParameter<RSAPrivateKey>(rsaPrivateKey));
    cipher.mgf1Hash = SHA256Digest();

    // Process the encryption
    return cipher.process(message);
  } on PlatformException catch (e) {
    throw KKException(
        "Error: RSA decryption failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.RSA_DECRYPTION_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_RSA_DECRYPT_INTERNAL, null, null);
  }
}

// NOTE: Private method
Future<Uint8List?> _rsaDecrypt(String keyAlias, Uint8List cipherData,
    [Uint8List? oaepLabel]) async {
  if (Platform.isAndroid) {
    try {
      return E2eeSdkFlutterPlatform.instance
          .rsaDecrypt(keyAlias, cipherData, oaepLabel);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: RSA decryption failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.RSA_DECRYPTION_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_RSA_DECRYPT,
          null,
          null);
    }
  } else if (Platform.isIOS) {
    try {
      final AsymmetricKeyPairObject? asymmetricKeyObject =
          await _getKeyPairFromFlutterSecureStorage(keyAlias);
      return _decryptRSA(
          asymmetricKeyObject!.privateKeyPem, cipherData, oaepLabel);
    } on KKException catch (e) {
      throw KKException(e.message!, e.code, e.details, e.stacktrace);
    }
  }
  return null;
}

// NOTE: Private method
Future<void> _importAES256GCMKey(
    String wrappingKeyAlias, String importedKeyAlias, Uint8List wrappedKey,
    [bool allowOverwrite = false, bool isDeviceBinding = false]) async {
  if (Platform.isAndroid || isDeviceBinding) {
    try {
      return E2eeSdkFlutterPlatform.instance.importAES256GCMKey(
          wrappingKeyAlias, importedKeyAlias, wrappedKey, allowOverwrite);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Import AES 256 GCM failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.IMPORT_AES_256_GCM_KEY_GENERATION_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_IMPORT_AES_256_KEY,
          null,
          null);
    }
  } else if (Platform.isIOS && !isDeviceBinding) {
    try {
      // Get wrapping private key from secure storage
      final AsymmetricKeyPairObject? keyPairObject =
          await _getKeyPairFromFlutterSecureStorage(wrappingKeyAlias);
      final privateKeyPem = keyPairObject!.privateKeyPem;

      // Unwrap the imported key
      final clientKey = _decryptRSA(privateKeyPem, wrappedKey);

      // Store client key to secure storage and overwrite the key if exist
      const FlutterSecureStorage secureStorage = FlutterSecureStorage();

      var existingClientKey = await secureStorage.read(key: importedKeyAlias);
      if (existingClientKey != null && allowOverwrite) {
        await secureStorage.delete(key: importedKeyAlias);
      } else if (existingClientKey != null) {
        throw KKException("AES key already exists!",
            ErrorCode.AES_KEY_ALREADY_EXISTS, null, null);
      }
      return secureStorage.write(
          key: importedKeyAlias, value: hex.encode(clientKey));
    } on KKException catch (e) {
      throw KKException(e.message!, e.code, e.details, e.stacktrace);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Import AES 256 GCM failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.IMPORT_AES_256_GCM_KEY_GENERATION_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_IMPORT_AES_256_KEY,
          null,
          null);
    }
  }
}

// NOTE: Private method
Future<Uint8List> _decryptAES256GCM(
    Uint8List ciphertext,
    Uint8List secretKeyBytes,
    Uint8List iv,
    Uint8List tag,
    Uint8List? aad) async {
  try {
    final crypto.SecretBox secretBox =
        crypto.SecretBox(ciphertext, nonce: iv, mac: crypto.Mac(tag));
    final List<int> decryptedData = await crypto.AesGcm.with256bits().decrypt(
        secretBox,
        secretKey: crypto.SecretKey(secretKeyBytes),
        aad: aad ?? Uint8List(0));
    return Uint8List.fromList(decryptedData);
  } on PlatformException catch (e) {
    throw KKException(
        "Error: AES 256 GCM decryption failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.AES_256_GCM_DECRYPTION_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_DECRYPT_AES_256_GCM, null, null);
  }
}

// NOTE: Private method
Future<Uint8List?> _aesDecrypt(String keyAlias, Uint8List cipherData,
    Uint8List tag, Uint8List iv, Uint8List? aad) async {
  if (Platform.isAndroid) {
    try {
      return E2eeSdkFlutterPlatform.instance
          .aesDecrypt(keyAlias, cipherData, tag, iv, aad);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: AES 256 GCM decryption failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.AES_256_GCM_DECRYPTION_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_AES_DECRYPT,
          null,
          null);
    }
  } else if (Platform.isIOS) {
    try {
      final clientKey = await _getClientKeyFromSecureStorage(keyAlias);
      return _decryptAES256GCM(cipherData, clientKey!, iv, tag, aad);
    } on KKException catch (e) {
      throw KKException(e.message!, e.code, e.details, e.stacktrace);
    }
  }
  return null;
}

// NOTE: Private method
Future<void> _generateECP256Keypair(String keyAlias,
    [bool requireAuth = true, bool allowOverwrite = false]) async {
  try {
    return E2eeSdkFlutterPlatform.instance.generateECP256Keypair(
        keyAlias, requireAuth = requireAuth, allowOverwrite = allowOverwrite);
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Generate EC key pair failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.EC_KEY_PAIR_GENERATION_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_GENERATE_EC_P256_KEYPAIR, null, null);
  }
}

// NOTE: Private method
Future<String?> _generateApplicationCSR(
    String keyAlias, DistinguishedName distinguishedName) async {
  try {
    return E2eeSdkFlutterPlatform.instance
        .generateApplicationCSR(keyAlias, distinguishedName);
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Generate application CSR failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.CSR_GENERATION_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_GENERATE_APPLICATION_CSR, null, null);
  }
}

// NOTE: Private method
Future<String?> _getDeviceId() async {
  // Try with android platform first, then with ios
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    try {
      final Future<AndroidDeviceInfo> androidInfo = deviceInfo.androidInfo;
      return (await androidInfo).id;
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Get android device id failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.GET_ANDROID_DEVICE_ID_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_GENERATE_DEVICE_ID,
          null,
          null);
    }
  } else if (Platform.isIOS) {
    try {
      final Future<IosDeviceInfo> iosInfo = deviceInfo.iosInfo;
      return (await iosInfo).identifierForVendor!;
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Get IOS device id failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.GET_IOS_DEVICE_ID_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_GENERATE_DEVICE_ID,
          null,
          null);
    }
  } else {
    return null;
  }
}

// NOTE: Private method
Future<void> _generateAES256Key(String keyAlias,
    [bool requireAuth = true, bool allowOverwrite = false]) async {
  try {
    return E2eeSdkFlutterPlatform.instance.generateAES256Key(
        keyAlias, requireAuth = requireAuth, allowOverwrite = allowOverwrite);
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Generate AES key failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.AES_KEY_GENERATION_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_GENERATE_AES_256_KEY, null, null);
  }
}

// NOTE: Private method
Future<bool?> _isSecureEnvironmentAvailable() async {
  try {
    return E2eeSdkFlutterPlatform.instance.isSecureEnvironmentAvailable();
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Check secure environment availability failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.SECURE_ENVIRONMENT_UNAVAILABLE,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException(
        "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_IS_SECURE_ENVIRONMENT_AVAILABLE,
        null,
        null);
  }
}

// NOTE: Private method
Future<bool?> _isSecureKeyImportAvailable() async {
  try {
    return E2eeSdkFlutterPlatform.instance.isSecureKeyImportAvailable();
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Check secure key import availability failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.SECURE_KEY_IMPORT_UNAVAILABLE,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_IS_SECURE_KEY_IMPORT_AVAILABLE, null, null);
  }
}

class E2eeSdkInSecureStorage {
  static const String _deviceIdKeypairName = "DeviceIdKeypair";
  static const String _devicePasswordKeyName = "DevicePasswordKey";
  static const String _devicePasswordIvName = "DevicePasswordIV";

  E2eeSdkInSecureStorage() {
    _init();
  }

  Future _init() async {
    final bool? isSecureEnvironmentAvailable =
        await _isSecureEnvironmentAvailable();
    if (isSecureEnvironmentAvailable == null || !isSecureEnvironmentAvailable) {
      throw KKException(
          "Error: The secure environment is not available on the platform.",
          ErrorCode.SECURE_ENVIRONMENT_UNAVAILABLE,
          null,
          null);
    }
  }

  Future<KMSWrappedKeyMetadata> fetchWrappedClientKey() async {
    try {
      final Uint8List aad = E2eeSdk().generateRandomBytes(AAD_LENGTH);
      final Uint8List iv = E2eeSdk().generateRandomBytes(GCM_IV_LENGTH);

      final EncryptedData encryptedData =
          await _aesEncrypt(CLIENT_KEY_ALIAS, aad, iv, null);

      const FlutterSecureStorage storage = FlutterSecureStorage();
      final Future<String?> encodedKMSWrappedClientKey =
          storage.read(key: KMS_WRAPPED_CLIENT_KEY_ALIAS);

      // Convert int to Uint8List
      final Uint8List encryptedDataLengthBytes =
          intToUint8List(encryptedData.ciphertext.length);

      // Sequence: tag, iv, ciphertext length, ciphertext
      final Uint8List encryptedDataBlock = serializeListOfUint8Lists([
        encryptedData.tag,
        iv,
        encryptedDataLengthBytes,
        encryptedData.ciphertext
      ]);

      return KMSWrappedKeyMetadata(aad, base64Encode(encryptedDataBlock),
          (await encodedKMSWrappedClientKey)!);
    } on KKException catch (e) {
      throw KKException(e.message!, e.code, e.details, e.stacktrace);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Fetch wrapped client key from secure storage failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.FETCH_WRAPPED_CLIENT_KEY_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_FETCH_WRAPPED_CLIENT_KEY,
          null,
          null);
    }
  }

  Future<String> generateRSAKeypair(
      [bool requireAuth = false, bool allowOverwrite = true]) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    try {
      await storage.delete(key: KMS_WRAPPED_CLIENT_KEY_ALIAS);
      // ignore: empty_catches
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Wrapped client key deletion failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.WRAPPED_CLIENT_KEY_GENERATION_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_GENERATE_RSA_KEY_PAIR_API,
          null,
          null);
    }
    try {
      await _generateRSAKeypairInSecureStorage(
          WRAPPING_KEY_ALIAS, WRAPPING_KEY_SIZE, requireAuth, allowOverwrite);
      return (await _getPublicKeyPEM(WRAPPING_KEY_ALIAS))!;
    } on KKException catch (e) {
      throw KKException(e.message!, e.code, e.details, e.stacktrace);
    }
  }

  Future<void> updateClientKey(
      String encodedWrappedClientKey, String encodedWrappedKMSKeyWrapped,
      [bool isDeviceBinding = false]) async {
    try {
      final Uint8List wrappedKMSKeyWrapped =
          base64Decode(encodedWrappedKMSKeyWrapped);
      final Future<Uint8List?> kmsKeyWrapped =
          _rsaDecrypt(WRAPPING_KEY_ALIAS, wrappedKMSKeyWrapped);

      const FlutterSecureStorage storage = FlutterSecureStorage();
      await storage.write(
          key: KMS_WRAPPED_CLIENT_KEY_ALIAS,
          value: base64Encode((await kmsKeyWrapped)!));

      final Uint8List wrappedClientKey = base64Decode(encodedWrappedClientKey);
      return _importAES256GCMKey(WRAPPING_KEY_ALIAS, CLIENT_KEY_ALIAS,
          wrappedClientKey, true, isDeviceBinding);
    } on KKException catch (e) {
      throw KKException(e.message!, e.code, e.details, e.stacktrace);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Update client key failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.CLIENT_KEY_UPDATED_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_UPDATE_CLIENT_KEY,
          null,
          null);
    }
  }

  Future<ResponseE2eeDecrypt> e2eeDecrypt(RequestE2eeDecrypt request) async {
    try {
      List<Future<Uint8List?>> processedMessages = [];
      for (final ciphertext in request.ciphertext) {
        processedMessages.add(_aesDecrypt(
            CLIENT_KEY_ALIAS,
            base64Decode(ciphertext.text),
            base64Decode(ciphertext.mac),
            base64Decode(ciphertext.iv),
            request.aad));
      }

      List<Uint8List> messages = [];
      for (final process in processedMessages) {
        messages.add((await process)!);
      }

      return ResponseE2eeDecrypt(messages);
    } on KKException catch (e) {
      throw KKException(e.message!, e.code, e.details, e.stacktrace);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: E2EE decryption failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.E2EE_DECRYPT_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_E2EE_DECRYPT,
          null,
          null);
    }
  }

  Future<void> setDeviceBinding() async {
    try {
      const FlutterSecureStorage secureStorage = FlutterSecureStorage();
      await secureStorage.write(key: DEVICE_BINDING_FLAG, value: "Yes");
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Set device binding flag failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.SET_DEVICE_BINDING_FLAG_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_SET_DEVICE_BINDING,
          null,
          null);
    }
  }

  Future<bool> isDeviceBinding() async {
    try {
      const FlutterSecureStorage secureStorage = FlutterSecureStorage();
      final String? deviceBindingFlag =
          await secureStorage.read(key: DEVICE_BINDING_FLAG);
      if (deviceBindingFlag != null) {
        return true;
      } else {
        return false;
      }
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Device binding flag not found.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.GET_DEVICE_BINDING_FLAG_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_IS_DEVICE_BINDING,
          null,
          null);
    }
  }

  Future<String> generateDeviceIdKeypair(
      DistinguishedName distinguishedName) async {
    try {
      await _generateECP256Keypair(_deviceIdKeypairName, true, true);
      final String? csr = await _generateApplicationCSR(
          _deviceIdKeypairName, distinguishedName);
      return csr!;
    } on KKException catch (e) {
      throw KKException(e.message!, e.code, e.details, e.stacktrace);
    }
  }

  Future<ResponseE2eeEncrypt> generateDeviceBasedEncryptedPassword(
      String authPublicKeyPEM, String oaepLabel) async {
    try {
      final deviceId = await _getDeviceId();
      const FlutterSecureStorage storage = FlutterSecureStorage();

      final Uint8List iv = E2eeSdk().generateRandomBytes(GCM_IV_LENGTH);
      await _generateAES256Key(_devicePasswordKeyName, true, true);
      await storage.write(key: _devicePasswordIvName, value: hex.encode(iv));

      // Calculate digest of password with salt
      final String passwordWithSalt = deviceId! + hex.encode(iv);
      final Uint8List passwordDigest = E2eeSdk().calculateDigest(
          Uint8List.fromList(utf8.encode(passwordWithSalt)), "SHA-512");

      final EncryptedData encryptedData = await _aesEncrypt(
          _devicePasswordKeyName, passwordDigest, iv, null, true);
      return E2eeSdk().e2eeEncrypt(RequestE2eeEncrypt(
          authPublicKeyPEM, oaepLabel, [encryptedData.ciphertext]));
    } on KKException catch (ex) {
      throw KKException(ex.message!, ex.code, ex.details, ex.stacktrace);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Generate device based encrypted password failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.INVALID_INPUT_PARAMETERS,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_GENERATE_DEVICE_BASED_ENCRYPTED_PASSWORD,
          null,
          null);
    }
  }

  Future<ResponseE2eeEncrypt> getDeviceBasedEncryptedPassword(
      String authPublicKeyPEM, String oaepLabel) async {
    try {
      final deviceId = await _getDeviceId();
      const FlutterSecureStorage storage = FlutterSecureStorage();

      final String? storedIv = await storage.read(key: _devicePasswordIvName);
      final Uint8List iv = Uint8List.fromList(hex.decode(storedIv!));

      // Calculate digest of password with salt
      final String passwordWithSalt = deviceId! + storedIv!;
      final Uint8List passwordDigest = E2eeSdk().calculateDigest(
          Uint8List.fromList(utf8.encode(passwordWithSalt)), "SHA-512");

      final EncryptedData encryptedData = await _aesEncrypt(
          _devicePasswordKeyName, passwordDigest, iv, null, true);
      return E2eeSdk().e2eeEncrypt(RequestE2eeEncrypt(
          authPublicKeyPEM, oaepLabel, [encryptedData.ciphertext]));
    } on KKException catch (ex) {
      throw KKException(ex.message!, ex.code, ex.details, ex.stacktrace);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Get device based encrypted password failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.INVALID_INPUT_PARAMETERS,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_GET_DEVICE_BASED_ENCRYPTED_PASSWORD,
          null,
          null);
    }
  }

  Future<Uint8List> signByDeviceIdKeypair(Uint8List plainData) async {
    try {
      final Uint8List? signatureBytes = await E2eeSdkFlutterPlatform.instance
          .generateSignature(_deviceIdKeypairName, plainData);
      return signatureBytes!;
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Sign by device id key pair failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.SIGN_BY_DEVICE_ID_KEYPAIR_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_SIGN_BY_DEVICE_ID_KEYPAIR,
          null,
          null);
    }
  }

  Future<Uint8List> signDigestByDeviceIdKeypair(Uint8List digest) async {
    // Verify the size of digest
    if (digest.length != 32 || digest.length != 48 || digest.length != 64) {
      throw KKException(
          "Error: Invalid digest length. The length must be 32, 48, or 64 bytes.",
          ErrorCode.INVALID_DIGEST_LENGTH,
          null,
          null);
    }

    try {
      final Uint8List? signatureBytes = await E2eeSdkFlutterPlatform.instance
          .generateDigestSignature(_deviceIdKeypairName, digest);
      return signatureBytes!;
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Sign digest by device id key pair failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.SIGN_DIGEST_BY_DEVICE_ID_KEYPAIR_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_SIGN_DIGEST_BY_DEVICE_ID_KEYPAIR,
          null,
          null);
    }
  }

  Future<void> unregisterDevice() async {
    try {
      // Remove device binding flag
      const FlutterSecureStorage secureStorage = FlutterSecureStorage();
      final deviceBindingFlag =
          await secureStorage.read(key: DEVICE_BINDING_FLAG);
      if (deviceBindingFlag != null) {
        await secureStorage.delete(key: DEVICE_BINDING_FLAG);
      }

      // Remove KMS wrapped client key
      final kmsWrappedClientKey =
          await secureStorage.read(key: KMS_WRAPPED_CLIENT_KEY_ALIAS);
      if (kmsWrappedClientKey != null) {
        await secureStorage.delete(key: KMS_WRAPPED_CLIENT_KEY_ALIAS);
      }

      // Remove IV
      final iv = await secureStorage.read(key: _devicePasswordIvName);
      if (iv != null) {
        await secureStorage.delete(key: _devicePasswordIvName);
      }

      // Remove client key
      await E2eeSdkFlutterPlatform.instance
          .deleteAES256GCMKey(CLIENT_KEY_ALIAS);

      // Remove password key
      await E2eeSdkFlutterPlatform.instance
          .deleteAES256GCMKey(_devicePasswordKeyName);

      // Remove wrapping key
      if (Platform.isAndroid) {
        await E2eeSdkFlutterPlatform.instance.deleteKeyPair(WRAPPING_KEY_ALIAS);
      } else if (Platform.isIOS) {
        // Remove KMS wrapped client key
        final clientKeyWrapper =
            await secureStorage.read(key: WRAPPING_KEY_ALIAS);
        if (clientKeyWrapper != null) {
          await secureStorage.delete(key: WRAPPING_KEY_ALIAS);
        }
      }

      // Remove device id key pair
      await E2eeSdkFlutterPlatform.instance.deleteKeyPair(_deviceIdKeypairName);
    } on KKException catch (e) {
      throw KKException(e.message!, e.code, e.details, e.stacktrace);
    } on PlatformException catch (e) {
      throw KKException(
          "Error: Device unregistration failed.\r\nStack trace: ${e.stacktrace}",
          ErrorCode.DEVICE_UNREGISTRATION_FAILED,
          e.details,
          e.stacktrace);
    } catch (e, s) {
      throw KKException(
          "Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
          ErrorCode.ERROR_IN_FUNCTION_UNREGISTER_DEVICE,
          null,
          null);
    }
  }

  Future<bool?> isSecureKeyImportAvailable() async {
    return _isSecureKeyImportAvailable();
  }
}
