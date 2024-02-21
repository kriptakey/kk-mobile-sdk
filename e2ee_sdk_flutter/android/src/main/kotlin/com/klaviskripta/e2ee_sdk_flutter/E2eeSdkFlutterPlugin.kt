package com.klaviskripta.e2ee_sdk_flutter

import android.os.Build
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.klaviskripta.e2ee_sdk_flutter.util.Crypto
import com.klaviskripta.e2ee_sdk_flutter.util.StrongboxInspector
import com.klaviskripta.e2ee_sdk_flutter.util.ErrorCode

/** E2eeSdkFlutterPlugin */
class E2eeSdkFlutterPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "e2ee_sdk_flutter")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "isSecureEnvironmentAvailable") {
            try {
                if (Build.VERSION.SDK_INT < 23) {
                    result.success(false)
                } else {
                    result.success(true)
                }
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.SECURE_ENVIRONMENT_UNAVAILABLE.toString(),
                    "Failed to get secure environment availability",
                    null
                )
            }
        } else if (call.method == "isStrongBoxAvailable") {
            try {
                result.success(StrongboxInspector().isStrongBoxAvailable())
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.STRONG_BOX_UNAVAILABLE.toString(),
                    "Failed to get strongbox availability",
                    null
                )
            }
        } else if (call.method == "generateApplicationCSR") {
            try {
                result.success(
                    Crypto().generateApplicationCSR(
                        call.argument("keyAlias")!!,
                        call.argument("commonName")!!,
                        call.argument("country")!!,
                        call.argument("location")!!,
                        call.argument("state")!!,
                        call.argument("organizationName")!!,
                        call.argument("organizationUnit")!!
                    )
                )
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.CSR_GENERATION_FAILED.toString(),
                    "Failed to generate application CSR",
                    null
                )
            }
        } else if (call.method == "encryptAES256GCM") {
            try {
                result.success(
                    Crypto().encryptAES256GCM(
                        call.argument("keyAlias")!!,
                        call.argument("plainData")!!,
                        call.argument("iv")!!,
                        call.argument("aad")
                    )
                )
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.AES_256_GCM_ENCRYPTION_FAILED.toString(),
                    "Failed to encrypt the plain data",
                    null
                )
            }
        } else if (call.method == "decryptAES256GCM") {
            try {
                result.success(
                    Crypto().decryptAES256GCM(
                        call.argument("keyAlias")!!,
                        call.argument("cipherData")!!,
                        call.argument("tag")!!,
                        call.argument("iv")!!,
                        call.argument("aad")
                    )
                )
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.AES_256_GCM_DECRYPTION_FAILED.toString(),
                    "Failed to decrypt the cipher data",
                    null
                )
            }
        } else if (call.method == "decryptRSA") {
            try {
                result.success(
                    Crypto().decryptRSA(
                        call.argument("keyAlias")!!,
                        call.argument("cipherData")!!,
                        call.argument("oaepLabel")
                    )
                )
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.RSA_DECRYPTION_FAILED.toString(),
                    "Failed to decrypt the cipher data",
                    null
                )
            }
        } else if (call.method == "signData") {
            try {
                result.success(
                    Crypto().signData(
                        call.argument("keyAlias")!!, call.argument("plainData")!!
                    )
                )
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.KEY_NOT_FOUND.toString(), "Failed to sign the plain data", null
                )
            }
        } else if (call.method == "generateAES256Key") {
            try {
                Crypto().generateAES256Key(
                    call.argument("keyAlias")!!,
                    call.argument("requireAuth")!!,
                    call.argument("allowOverwrite")!!
                )
                result.success(null)
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.AES_KEY_GENERATION_FAILED.toString(),
                    "Failed to generate AES-256 key",
                    null
                )
            }
        } else if (call.method == "generateECP256Keypair") {
            try {
                Crypto().generateECP256Keypair(
                    call.argument("keyAlias")!!,
                    call.argument("requireAuth")!!,
                    call.argument("allowOverwrite")!!
                )
                result.success(null)
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.EC_KEY_PAIR_GENERATION_FAILED.toString(),
                    "Failed to generate EC-P256 keypair",
                    null
                )
            }
        } else if (call.method == "generateRSAKeypair") {
            try {
                Crypto().generateRSAKeypair(
                    call.argument("keyAlias")!!,
                    call.argument("keySize")!!,
                    call.argument("requireAuth")!!,
                    call.argument("allowOverwrite")!!
                )
                result.success(null)
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.RSA_KEY_PAIR_GENERATION_FAILED.toString(),
                    "Failed to generate RSA keypair",
                    null
                )
            }
        } else if (call.method == "importAES256GCMKey") {
            try {
                Crypto().importAES256GCMKey(
                    call.argument("wrappingKeyAlias")!!,
                    call.argument("importedKeyAlias")!!,
                    call.argument("wrappedKey")!!,
                    call.argument("allowOverwrite")!!
                )
                result.success(null)
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.IMPORT_AES_256_GCM_KEY_GENERATION_FAILED.toString(),
                    "Failed to import AES-256 key",
                    null
                )
            }
        } else if (call.method == "getPublicKeyPEM") {
            try {
                result.success(Crypto().getPublicKeyPEM(call.argument("keyAlias")!!))
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.KEY_NOT_FOUND.toString(),
                    "Failed to fetch public key in PEM format",
                    null
                )
            }
        } else if (call.method == "signDigest") {
            try {
                result.success(
                    Crypto().signDigest(
                        call.argument("keyAlias")!!, call.argument("digest")!!
                    )
                )
            } catch (ex: Exception) {
                result.error(ErrorCode.KEY_NOT_FOUND.toString(), "Failed to sign the digest", null)
            }
        } else if (call.method == "deleteAES256GCMKey") {
            try {
                Crypto().deleteKey(
                    call.argument("keyAlias")!!
                )
                result.success(null)
            } catch (ex: Exception) {
                result.error(ErrorCode.KEY_DELETION_FAILED.toString(), "Failed to delete key", null)
            }
        } else if (call.method == "deleteKeyPair") {
            try {
                Crypto().deleteKey(
                    call.argument("keyAlias")!!
                )
                result.success(null)
            } catch (ex: Exception) {
                result.error(
                    ErrorCode.KEY_DELETION_FAILED.toString(),
                    "Failed to delete key pair",
                    null
                )
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
