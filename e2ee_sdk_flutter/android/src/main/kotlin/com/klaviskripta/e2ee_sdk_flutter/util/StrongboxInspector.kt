package com.klaviskripta.e2ee_sdk_flutter.util

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import androidx.annotation.RequiresApi
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.KeyStoreException
import java.security.spec.ECGenParameterSpec

class StrongboxInspector {
    @RequiresApi(Build.VERSION_CODES.P)
    public fun isStrongBoxAvailable(): Boolean? {
        // Generate random key to check strong box availability
        val isStrongBoxAvailable = generateSampleKeyPairFromSecureStorage(Constants.SAMPLE_KEY_PAIR)
        deleteKey(Constants.SAMPLE_KEY_PAIR)
        return isStrongBoxAvailable
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun generateSampleKeyPairFromSecureStorage(keyName: String): Boolean {
        try {
            val keyPairGenerator: KeyPairGenerator =
                    KeyPairGenerator.getInstance(
                            KeyProperties.KEY_ALGORITHM_EC,
                            Constants.ANDROID_KEY_STORE
                    )
            val paramSpec =
                    KeyGenParameterSpec.Builder(
                                    keyName,
                                    KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
                            )
                            .run {
                                setAlgorithmParameterSpec(
                                        ECGenParameterSpec(Constants.EC_GEN_PARAMETER_SPEC)
                                )
                                setDigests(
                                        KeyProperties.DIGEST_SHA256,
                                        KeyProperties.DIGEST_SHA384,
                                        KeyProperties.DIGEST_SHA512
                                )
                                when {
                                    // Android lower than 9
                                    Build.VERSION.SDK_INT < 9 -> {
                                        return false
                                    }
                                    // Android bigger than 9
                                    else -> {
                                        setIsStrongBoxBacked(true)
                                    }
                                }
                                build()
                            }
            keyPairGenerator.initialize(paramSpec)
            keyPairGenerator.generateKeyPair()
        } catch (ex: StrongBoxUnavailableException) {
            return false
        } catch (ex: Exception) {
            ex.printStackTrace()
            throw ex
        }
        return true
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun deleteKey(keyAlias: String) {
        val keyStore = KeyStore.getInstance(Constants.ANDROID_KEY_STORE)
        keyStore.load(null)

        try {
            keyStore.deleteEntry(keyAlias)
        } catch (ex: KeyStoreException) {
            ex.printStackTrace()
            throw ex
        }
    }
}