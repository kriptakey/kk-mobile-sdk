package com.klaviskripta.e2ee_sdk_flutter.util

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.WrappedKeyEntry
import androidx.annotation.RequiresApi
import java.io.StringWriter
import java.security.Key
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.PublicKey
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import java.security.spec.RSAKeyGenParameterSpec
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.OAEPParameterSpec
import javax.crypto.spec.PSource
import javax.security.auth.x500.X500Principal
import org.bouncycastle.asn1.*
import org.bouncycastle.operator.jcajce.JcaContentSignerBuilder
import org.bouncycastle.pkcs.PKCS10CertificationRequestBuilder
import org.bouncycastle.pkcs.jcajce.JcaPKCS10CertificationRequestBuilder
import org.bouncycastle.util.io.pem.PemObject
import org.bouncycastle.util.io.pem.PemWriter
import java.security.spec.MGF1ParameterSpec

class Crypto {
    @RequiresApi(Build.VERSION_CODES.P)
    public fun generateAES256Key(keyAlias: String, requireAuth: Boolean, allowOverwrite: Boolean) {
        val keyStore = KeyStore.getInstance(Constants.ANDROID_KEY_STORE)
        keyStore.load(null)
        if (!allowOverwrite and keyStore.isKeyEntry(keyAlias))
            throw KMSException("Key alias already exist!")

        // If key does not exist, then create a new key with the given key name
        val isStrongBoxAvailable = (StrongboxInspector().isStrongBoxAvailable() ?: false)
        try {
            val keyGenerator: KeyGenerator =
                KeyGenerator.getInstance(
                    KeyProperties.KEY_ALGORITHM_AES,
                    Constants.ANDROID_KEY_STORE
                )
            val paramSpec =
                KeyGenParameterSpec.Builder(
                    keyAlias,
                    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
                )
                    .run {
                        // This is required to let the application pass the IV instead of
                        // the IV generated automatically by the Cipher class
                        setRandomizedEncryptionRequired(false)

                        setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                        setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                        setKeySize(Constants.AES_KEY_SIZE)
                        if (requireAuth) {
                            when {
                                // Android lower than 6
                                Build.VERSION.SDK_INT < 23 -> {
                                    throw KMSException("Unsupported Android version!")
                                }
                                // Android 6 - 8
                                Build.VERSION.SDK_INT in 23..27 -> {
                                    // No StrongBox available before Android 9
                                    setUserAuthenticationRequired(true)
                                    setUserAuthenticationValidityDurationSeconds(
                                        Constants.USER_VALIDITY_DURATION
                                    )
                                }
                                // Android 9 - 10
                                Build.VERSION.SDK_INT in 28..29 -> {
                                    if (isStrongBoxAvailable) {
                                        setIsStrongBoxBacked(true)
                                    }
                                    // No biometric requirement before Android 11
                                    setUserAuthenticationRequired(true)
                                    setUserAuthenticationValidityDurationSeconds(
                                        Constants.USER_VALIDITY_DURATION
                                    )
                                }
                                // Android bigger than 10
                                else -> {
                                    if (isStrongBoxAvailable) {
                                        setIsStrongBoxBacked(true)
                                    }
                                    setUserAuthenticationRequired(true)
                                    setUserAuthenticationParameters(
                                        Constants.USER_AUTHENTICATED_DURATION,
                                        KeyProperties.AUTH_BIOMETRIC_STRONG or
                                                KeyProperties.AUTH_DEVICE_CREDENTIAL
                                    )
                                }
                            }
                        }
                        build()
                    }
            keyGenerator.init(paramSpec)
            keyGenerator.generateKey()
        } catch (ex: Exception) {
            ex.printStackTrace()
            throw ex
        }
        return
    }

    @RequiresApi(Build.VERSION_CODES.P)
    public fun generateECP256Keypair(
        keyAlias: String,
        requireAuth: Boolean,
        allowOverwrite: Boolean
    ) {
        val keyStore = KeyStore.getInstance(Constants.ANDROID_KEY_STORE)
        keyStore.load(null)
        if (!allowOverwrite and keyStore.isKeyEntry(keyAlias))
            throw KMSException("Key alias already exist!")

        // If key does not exist, then create a new key with the given key name
        val isStrongBoxAvailable = (StrongboxInspector().isStrongBoxAvailable() ?: false)
        try {
            val keyPairGenerator: KeyPairGenerator =
                KeyPairGenerator.getInstance(
                    KeyProperties.KEY_ALGORITHM_EC,
                    Constants.ANDROID_KEY_STORE
                )
            val paramSpec =
                KeyGenParameterSpec.Builder(
                    keyAlias,
                    KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
                )
                    .run {
                        setAlgorithmParameterSpec(
                            ECGenParameterSpec(Constants.EC_GEN_PARAMETER_SPEC)
                        )
                        setDigests(
                            KeyProperties.DIGEST_NONE,
                            KeyProperties.DIGEST_SHA256,
                            KeyProperties.DIGEST_SHA384,
                            KeyProperties.DIGEST_SHA512
                        )
                        if (requireAuth) {
                            when {
                                // Android lower than 6
                                Build.VERSION.SDK_INT < 23 -> {
                                    throw KMSException("Unsupported Android version!")
                                }
                                // Android 6 - 8
                                Build.VERSION.SDK_INT in 23..27 -> {
                                    // No StrongBox available before Android 9
                                    setUserAuthenticationRequired(true)
                                    setUserAuthenticationValidityDurationSeconds(
                                        Constants.USER_VALIDITY_DURATION
                                    )
                                }
                                // Android 9 - 10
                                Build.VERSION.SDK_INT in 28..29 -> {
                                    if (isStrongBoxAvailable) {
                                        setIsStrongBoxBacked(true)
                                    }
                                    // No biometric requirement before Android 11
                                    setUserAuthenticationRequired(true)
                                    setUserAuthenticationValidityDurationSeconds(
                                        Constants.USER_VALIDITY_DURATION
                                    )
                                }
                                // Android bigger than 10
                                else -> {
                                    if (isStrongBoxAvailable) {
                                        setIsStrongBoxBacked(true)
                                    }
                                    setUserAuthenticationRequired(true)
                                    setUserAuthenticationParameters(
                                        Constants.USER_AUTHENTICATED_DURATION,
                                        KeyProperties.AUTH_BIOMETRIC_STRONG or
                                                KeyProperties.AUTH_DEVICE_CREDENTIAL
                                    )
                                }
                            }
                        }
                        build()
                    }
            keyPairGenerator.initialize(paramSpec)
            keyPairGenerator.generateKeyPair()
        } catch (ex: Exception) {
            ex.printStackTrace()
            throw ex
        }
        return
    }

    @RequiresApi(Build.VERSION_CODES.P)
    public fun generateRSAKeypair(
        keyAlias: String,
        keySize: Int,
        requireAuth: Boolean,
        allowOverwrite: Boolean
    ) {
        val keyStore = KeyStore.getInstance(Constants.ANDROID_KEY_STORE)
        keyStore.load(null)
        if (!allowOverwrite and keyStore.isKeyEntry(keyAlias))
            throw KMSException("Key alias already exist!")

        // If key does not exist, then create a new key with the given key name
        val isStrongBoxAvailable = (StrongboxInspector().isStrongBoxAvailable() ?: false)
        try {
            val keyPairGenerator: KeyPairGenerator =
                KeyPairGenerator.getInstance(
                    KeyProperties.KEY_ALGORITHM_RSA,
                    Constants.ANDROID_KEY_STORE
                )
            val paramSpec =
                KeyGenParameterSpec.Builder(
                    keyAlias,
                    KeyProperties.PURPOSE_ENCRYPT or
                            KeyProperties.PURPOSE_DECRYPT or
                            KeyProperties.PURPOSE_SIGN or
                            KeyProperties.PURPOSE_VERIFY or
                            KeyProperties.PURPOSE_WRAP_KEY
                )
                    .run {
                        setAlgorithmParameterSpec(
                            RSAKeyGenParameterSpec(keySize, RSAKeyGenParameterSpec.F4)
                        )
                        setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_OAEP)
                        setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
                        setDigests(
                            KeyProperties.DIGEST_NONE,
                            KeyProperties.DIGEST_SHA256,
                            KeyProperties.DIGEST_SHA384,
                            KeyProperties.DIGEST_SHA512
                        )
                        setBlockModes(KeyProperties.BLOCK_MODE_ECB)
                        if (requireAuth) {
                            when {
                                // Android lower than 6
                                Build.VERSION.SDK_INT < 23 -> {
                                    throw KMSException("Unsupported Android version!")
                                }
                                // Android 6 - 8
                                Build.VERSION.SDK_INT in 23..27 -> {
                                    // No StrongBox available before Android 9
                                    setUserAuthenticationRequired(true)
                                    setUserAuthenticationValidityDurationSeconds(
                                        Constants.USER_VALIDITY_DURATION
                                    )
                                }
                                // Android 9 - 10
                                Build.VERSION.SDK_INT in 28..29 -> {
                                    if (isStrongBoxAvailable) {
                                        setIsStrongBoxBacked(true)
                                    }
                                    // No biometric requirement before Android 11
                                    setUserAuthenticationRequired(true)
                                    setUserAuthenticationValidityDurationSeconds(
                                        Constants.USER_VALIDITY_DURATION
                                    )
                                }
                                // Android bigger than 10
                                else -> {
                                    if (isStrongBoxAvailable) {
                                        setIsStrongBoxBacked(true)
                                    }
                                    setUserAuthenticationRequired(true)
                                    setUserAuthenticationParameters(
                                        Constants.USER_AUTHENTICATED_DURATION,
                                        KeyProperties.AUTH_BIOMETRIC_STRONG or
                                                KeyProperties.AUTH_DEVICE_CREDENTIAL
                                    )
                                }
                            }
                        }
                        build()
                    }
            keyPairGenerator.initialize(paramSpec)
            keyPairGenerator.generateKeyPair()
        } catch (ex: Exception) {
            ex.printStackTrace()
            throw ex
        }
        return
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun getKey(keyAlias: String): Key? {
        val keyStore = KeyStore.getInstance(Constants.ANDROID_KEY_STORE)
        keyStore.load(null)
        return keyStore.getKey(keyAlias, null)
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun getPublicKey(keyAlias: String): Key? {
        val keyStore = KeyStore.getInstance(Constants.ANDROID_KEY_STORE)
        keyStore.load(null)
        keyStore.getCertificate(keyAlias)?.let {
            return it.getPublicKey()
        }
        return null
    }

    @RequiresApi(Build.VERSION_CODES.P)
    public fun getPublicKeyPEM(keyAlias: String): String? {
        getPublicKey(keyAlias)?.let {
            // Create a StringWriter to write the PEM format
            val stringWriter = StringWriter()
            val pemWriter = PemWriter(stringWriter)

            // Create a PemObject with appropriate headers (e.g., "PUBLIC KEY")
            val pemObject = PemObject("PUBLIC KEY", it.encoded)

            // Write the PEM object to the StringWriter
            pemWriter.writeObject(pemObject)
            pemWriter.close()

            // Get the PEM formatted public key as a string
            return stringWriter.toString()
        }
        return null
    }

    @RequiresApi(Build.VERSION_CODES.P)
    public fun generateApplicationCSR(
        keyAlias: String,
        commonName: String,
        country: String,
        location: String,
        state: String,
        organizationName: String,
        organizationUnit: String
    ): String {
        try {
            val privateKey: Key? = getKey(keyAlias)
            val publicKey: Key? = getPublicKey(keyAlias)
            // Generate PKCS10 CSR
            // Common Name
            val x500PrincipalBuilder: StringBuilder = StringBuilder("CN=")
            x500PrincipalBuilder.append(commonName)

            // Country
            x500PrincipalBuilder.append(",")
            x500PrincipalBuilder.append("C=")
            x500PrincipalBuilder.append(country)

            // Location
            x500PrincipalBuilder.append(",")
            x500PrincipalBuilder.append("L=")
            x500PrincipalBuilder.append(location)

            // State
            x500PrincipalBuilder.append(",")
            x500PrincipalBuilder.append("ST=")
            x500PrincipalBuilder.append(state)

            // Organization
            x500PrincipalBuilder.append(",")
            x500PrincipalBuilder.append("O=")
            x500PrincipalBuilder.append(organizationName)

            // Organization unit
            x500PrincipalBuilder.append(",")
            x500PrincipalBuilder.append("OU=")
            x500PrincipalBuilder.append(organizationUnit)

            val x500Principal = X500Principal(x500PrincipalBuilder.toString())
            val pkcs10CsrBuilder: PKCS10CertificationRequestBuilder =
                JcaPKCS10CertificationRequestBuilder(x500Principal, (publicKey as PublicKey))
            val contentSignerBuilder = JcaContentSignerBuilder(Constants.SIGNATURE_ALGORITHM)

            // contentSignerBuilder will throw if user is not authenticated
            val signer = contentSignerBuilder.build((privateKey as PrivateKey))
            val csr = pkcs10CsrBuilder.build(signer)

            val csrPemObject = PemObject("CERTIFICATE REQUEST", csr.encoded)
            val csrAsString = StringWriter()
            val pemWriter = PemWriter(csrAsString)
            pemWriter.writeObject(csrPemObject)
            pemWriter.close()
            csrAsString.close()

            return csrAsString.toString()
        } catch (ex: Exception) {
            ex.printStackTrace()
            throw ex
        }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    public fun encryptAES256GCM(
        keyAlias: String,
        plainData: ByteArray,
        iv: ByteArray,
        aad: ByteArray?
    ): ByteArray {
        try {
            val secretKey: Key? = getKey(keyAlias)
            val cipher = Cipher.getInstance(Constants.AES_CIPHER_MODE)
            cipher.init(
                Cipher.ENCRYPT_MODE,
                secretKey,
                GCMParameterSpec(Constants.AUTHENTICATION_TAG_LENGTH, iv)
            )
            aad?.let { cipher.updateAAD(aad) }
            return cipher.doFinal(plainData)
        } catch (ex: Exception) {
            ex.printStackTrace()
            throw ex
        }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    public fun decryptAES256GCM(
        keyAlias: String,
        cipherData: ByteArray,
        tag: ByteArray,
        iv: ByteArray,
        aad: ByteArray?
    ): ByteArray {
        try {
            val secretKey: Key? = getKey(keyAlias)
            val cipher = Cipher.getInstance(Constants.AES_CIPHER_MODE)
            cipher.init(
                Cipher.DECRYPT_MODE,
                secretKey,
                GCMParameterSpec(Constants.AUTHENTICATION_TAG_LENGTH, iv)
            )
            aad?.let { cipher.updateAAD(aad) }
            return cipher.doFinal(cipherData + tag)
        } catch (ex: Exception) {
            ex.printStackTrace()
            throw ex
        }
    }


    @RequiresApi(Build.VERSION_CODES.P)
    public fun decryptRSA(
            keyAlias: String,
            cipherData: ByteArray,
            oaepLabel: ByteArray?
    ): ByteArray {
        try {
            val privateKey: Key? = getKey(keyAlias)
            val cipher = Cipher.getInstance(Constants.RSA_CIPHER_MODE)
            cipher.init(
                    Cipher.DECRYPT_MODE,
                    privateKey,
                    OAEPParameterSpec(
                            Constants.RSA_OAEP_HASH_PARAMETER_SPEC,
                            Constants.RSA_OAEP_MGF1_PARAMETER_SPEC,
                            MGF1ParameterSpec.SHA1,
                            if (oaepLabel == null) PSource.PSpecified.DEFAULT else PSource.PSpecified(oaepLabel)
                    )
            )
            return cipher.doFinal(cipherData)
        } catch (ex: Exception) {
            ex.printStackTrace()
            throw ex
        }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    public fun signData(keyAlias: String, plainData: ByteArray): ByteArray {
        val keyPair: Key? = getKey(keyAlias)
        try {
            val signer = Signature.getInstance(Constants.SIGNATURE_ALGORITHM)
            signer.initSign((keyPair as PrivateKey))
            signer.update(plainData)
            return signer.sign()
        } catch (ex: Exception) {
            ex.printStackTrace()
            throw ex
        }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    public fun signDigest(keyAlias: String, digest: ByteArray): ByteArray {
        val keyPair: Key? = getKey(keyAlias)
        try {
            val signer = Signature.getInstance(Constants.NODIGEST_SIGNATURE_ALGORITHM)
            signer.initSign((keyPair as PrivateKey))
            signer.update(digest)
            return signer.sign()
        } catch (ex: Exception) {
            ex.printStackTrace()
            throw ex
        }
    }

    // References:
    // https://developer.android.com/reference/kotlin/android/security/keystore/WrappedKeyEntry
    // References:
    // https://cs.android.com/android/platform/superproject/main/+/main:cts/tests/tests/keystore/src/android/keystore/cts/ImportWrappedKeyTest.java
    @RequiresApi(Build.VERSION_CODES.P)
    public fun importAES256GCMKey(
        wrappingKeyAlias: String,
        importedKeyAlias: String,
        wrappedKey: ByteArray,
        allowOverwrite: Boolean
    ) {
        try {
            val keyStore = KeyStore.getInstance(Constants.ANDROID_KEY_STORE)
            keyStore.load(null)
            if (!allowOverwrite and keyStore.isKeyEntry(importedKeyAlias))
                throw KMSException("Key alias already exist!")

            val paramSpec =
                KeyGenParameterSpec.Builder(wrappingKeyAlias, KeyProperties.PURPOSE_WRAP_KEY)
                    .setDigests(KeyProperties.DIGEST_SHA256)
                    .build()
            val wrappingKeyEntry: WrappedKeyEntry =
                WrappedKeyEntry(
                    wrappedKey,
                    wrappingKeyAlias,
                    Constants.RSA_CIPHER_MODE,
                    paramSpec
                )
            keyStore.setEntry(importedKeyAlias, wrappingKeyEntry, null)
        } catch (ex: Exception) {
            ex.printStackTrace()
            throw ex
        }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    public fun deleteKey(keyAlias: String) {
        try {
            val keyStore = KeyStore.getInstance(Constants.ANDROID_KEY_STORE)
            keyStore.load(null)
            keyStore.getKey(keyAlias, null)?.let { keyStore.deleteEntry(keyAlias) }
        } catch (ex: Exception) {
            ex.printStackTrace()
            throw ex
        }
    }
}