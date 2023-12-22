import 'dart:typed_data';
import 'package:flutter/services.dart';

import 'package:cryptography/cryptography.dart' as crypto;
import 'package:e2ee_sdk_flutter/core/error_code.dart';
import 'package:e2ee_sdk_flutter/core/exceptions.dart';

import 'package:kms_e2ee_package/src/kk/structure.dart';

// NOTE: Private method
Future<EncryptedData> encryptAES256GCM(Uint8List message,
    Uint8List secretKeyBytes, Uint8List iv, Uint8List? aad) async {
  try {
    final crypto.SecretBox secretBox = await crypto.AesGcm.with256bits()
        .encrypt(message,
            secretKey: crypto.SecretKey(secretKeyBytes),
            nonce: iv,
            aad: aad ?? Uint8List(0));

    return EncryptedData(iv, Uint8List.fromList(secretBox.mac.bytes),
        Uint8List.fromList(secretBox.cipherText));
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Encryption with AES-256-GCM failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.AES_256_GCM_ENCRYPTION_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_ENCRYPT_AES_256_GCM, null, null);
  }
}
