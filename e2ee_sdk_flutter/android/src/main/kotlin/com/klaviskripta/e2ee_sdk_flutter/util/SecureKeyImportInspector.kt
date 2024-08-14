package com.klaviskripta.e2ee_sdk_flutter.util

import android.os.Build
import android.security.keystore.SecureKeyImportUnavailableException
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.WrappedKeyEntry

import androidx.annotation.RequiresApi
import javax.crypto.KeyGenerator
import javax.crypto.spec.OAEPParameterSpec
import java.security.spec.MGF1ParameterSpec
import java.security.Key
import java.security.KeyStore
import java.security.KeyStore.Entry
import java.security.spec.AlgorithmParameterSpec
import java.security.spec.RSAKeyGenParameterSpec

import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec
import java.security.PublicKey
import java.security.SecureRandom
import javax.crypto.spec.PSource
import javax.crypto.Cipher
import java.util.Arrays
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStoreException

import org.bouncycastle.asn1.ASN1Encoding
import org.bouncycastle.asn1.ASN1EncodableVector
import org.bouncycastle.asn1.ASN1Integer
import org.bouncycastle.asn1.DERNull
import org.bouncycastle.asn1.DEROctetString
import org.bouncycastle.asn1.DERSequence
import org.bouncycastle.asn1.DERSet
import org.bouncycastle.asn1.DERTaggedObject

class SecureKeyImportInspector {
    var random: SecureRandom = SecureRandom()

    @RequiresApi(Build.VERSION_CODES.P)
    public fun isSecureKeyImportAvailable(): Boolean? {
        val canSecurelyImportKey: Boolean? = importWrappedKeySample()
        deleteKey(Constants.SAMPLE_AES_KEY_ALIAS)
        deleteKey(Constants.SAMPLE_WRAPPING_KEY_ALIAS)
        return canSecurelyImportKey
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun removeTagType(tag: Int): Int {
        val kmTagTypeMask = 0x0FFFFFFF
        return tag and kmTagTypeMask
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun importWrappedKeySample(): Boolean? {
        val kg: KeyGenerator = KeyGenerator.getInstance(Constants.AES_ALGO_STRING)
        kg.init(Constants.AES_KEY_SIZE)
        val swKey: Key = kg.generateKey()

        val keyMaterial: ByteArray = swKey.getEncoded()
        val mask = ByteArray(32) // Zero mask
        try {
            importWrappedKey(
                wrapKey(
                    genKeyPair(Constants.SAMPLE_WRAPPING_KEY_ALIAS).getPublic(),
                    keyMaterial,
                    mask,
                    Constants.KM_KEY_FORMAT_RAW,
                    makeAesAuthList(keyMaterial.size.toLong() * 8),
                    true
                ),
                Constants.SAMPLE_WRAPPING_KEY_ALIAS
            )
        } catch (e: SecureKeyImportUnavailableException) {
            return false
        } catch (e: KeyStoreException) {
            return false
        }
        return true
    }

    // References:
    // https://cs.android.com/android/platform/superproject/main/+/main:cts/tests/tests/keystore/src/android/keystore/cts/ImportWrappedKeyTest.java
    @RequiresApi(Build.VERSION_CODES.P)
    @kotlin.Throws(Exception::class)
    private fun importWrappedKey(wrappedKey: ByteArray, wrappingKeyAlias: String) {
        val keyStore: KeyStore = KeyStore.getInstance(Constants.ANDROID_KEY_STORE)
        keyStore.load(null, null)
        val spec: AlgorithmParameterSpec = KeyGenParameterSpec.Builder(
            wrappingKeyAlias,
            KeyProperties.PURPOSE_WRAP_KEY
        )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .build()
        val wrappedKeyEntry: Entry = WrappedKeyEntry(
            wrappedKey, wrappingKeyAlias,
            Constants.RSA_CIPHER_MODE, spec
        )
        keyStore.setEntry(Constants.SAMPLE_AES_KEY_ALIAS, wrappedKeyEntry, null)
    }

    // References:
    // https://cs.android.com/android/platform/superproject/main/+/main:cts/tests/tests/keystore/src/android/keystore/cts/ImportWrappedKeyTest.java
    @RequiresApi(Build.VERSION_CODES.P)
    @kotlin.Throws(Exception::class)
    private fun wrapKey(
        publicKey: PublicKey?, keyMaterial: ByteArray?, mask: ByteArray?,
        keyFormat: Long, authorizationList: DERSequence?, correctWrappingRequired: Boolean
    ): ByteArray {
        // Build description
        val descriptionItems: ASN1EncodableVector = ASN1EncodableVector()
        descriptionItems.add(ASN1Integer(keyFormat))
        descriptionItems.add(authorizationList)
        val wrappedKeyDescription: DERSequence = DERSequence(descriptionItems)
        // Generate 12 byte initialization vector
        val iv = ByteArray(12)
        random.nextBytes(iv)
        // Generate 256 bit AES key. This is the ephemeral key used to encrypt the secure key.
        val aesKeyBytes = ByteArray(32)
        random.nextBytes(aesKeyBytes)
        // Encrypt ephemeral keys
        val spec: OAEPParameterSpec =
            OAEPParameterSpec(
                Constants.RSA_OAEP_HASH_PARAMETER_SPEC,
                Constants.RSA_OAEP_MGF1_PARAMETER_SPEC,
                MGF1ParameterSpec.SHA1,
                PSource.PSpecified.DEFAULT
            )
        val pkCipher: Cipher = Cipher.getInstance(Constants.RSA_CIPHER_MODE)
        if (correctWrappingRequired) {
            pkCipher.init(Cipher.ENCRYPT_MODE, publicKey, spec)
        } else {
            // Use incorrect OAEPParameters while initializing cipher. By default, main digest and
            // MGF1 digest are SHA-1 here.
            pkCipher.init(Cipher.ENCRYPT_MODE, publicKey)
        }
        val encryptedEphemeralKeys: ByteArray = pkCipher.doFinal(aesKeyBytes)
        // Encrypt secure key
        val cipher: Cipher = Cipher.getInstance(Constants.AES_CIPHER_MODE)
        val secretKeySpec: SecretKeySpec = SecretKeySpec(aesKeyBytes, Constants.AES_ALGO_STRING)
        val gcmParameterSpec: GCMParameterSpec = GCMParameterSpec(128, iv)
        cipher.init(Cipher.ENCRYPT_MODE, secretKeySpec, gcmParameterSpec)
        val aad: ByteArray = wrappedKeyDescription.getEncoded()
        cipher.updateAAD(aad)
        var encryptedSecureKey: ByteArray = cipher.doFinal(keyMaterial)
        // Get GCM tag. Java puts the tag at the end of the ciphertext data :(
        val len = encryptedSecureKey.size
        val tagSize: Int = (128 / 8)
        val tag: ByteArray = Arrays.copyOfRange(encryptedSecureKey, len - tagSize, len)
        // Remove GCM tag from end of output
        encryptedSecureKey = Arrays.copyOfRange(encryptedSecureKey, 0, len - tagSize)
        // Build ASN.1 encoded sequence WrappedKeyWrapper
        val items: ASN1EncodableVector = ASN1EncodableVector()
        items.add(ASN1Integer(0))
        items.add(DEROctetString(encryptedEphemeralKeys))
        items.add(DEROctetString(iv))
        items.add(wrappedKeyDescription)
        items.add(DEROctetString(encryptedSecureKey))
        items.add(DEROctetString(tag))
        return DERSequence(items).getEncoded(ASN1Encoding.DER)
    }

    // References:
    // https://cs.android.com/android/platform/superproject/main/+/main:cts/tests/tests/keystore/src/android/keystore/cts/ImportWrappedKeyTest.java
    @RequiresApi(Build.VERSION_CODES.P)
    private fun makeAesAuthList(size: Long): DERSequence {
        return makeSymKeyAuthList(size, Constants.KM_ALGORITHM_AES)
    }

    // References:
    // https://cs.android.com/android/platform/superproject/main/+/main:cts/tests/tests/keystore/src/android/keystore/cts/ImportWrappedKeyTest.java
    @RequiresApi(Build.VERSION_CODES.P)
    private fun makeSymKeyAuthList(size: Long, algo: Long): DERSequence {
        val allPurposes: ASN1EncodableVector = ASN1EncodableVector()
        allPurposes.add(ASN1Integer(Constants.KM_PURPOSE_ENCRYPT))
        allPurposes.add(ASN1Integer(Constants.KM_PURPOSE_DECRYPT))
        val purposeSet: DERSet = DERSet(allPurposes)
        val purpose: DERTaggedObject =
            DERTaggedObject(true, removeTagType(Constants.KM_TAG_PURPOSE), purposeSet)
        val algorithm: DERTaggedObject =
            DERTaggedObject(true, removeTagType(Constants.KM_TAG_ALGORITHM), ASN1Integer(algo))
        val keySize: DERTaggedObject =
            DERTaggedObject(true, removeTagType(Constants.KM_TAG_KEY_SIZE), ASN1Integer(size))
        val allBlockModes: ASN1EncodableVector = ASN1EncodableVector()
        allBlockModes.add(ASN1Integer(Constants.KM_MODE_ECB))
        allBlockModes.add(ASN1Integer(Constants.KM_MODE_CBC))
        val blockModeSet: DERSet = DERSet(allBlockModes)
        val blockMode: DERTaggedObject =
            DERTaggedObject(true, removeTagType(Constants.KM_TAG_BLOCK_MODE), blockModeSet)
        val allPaddings: ASN1EncodableVector = ASN1EncodableVector()
        allPaddings.add(ASN1Integer(Constants.KM_PAD_PKCS7))
        allPaddings.add(ASN1Integer(Constants.KM_PAD_NONE))
        val paddingSet: DERSet = DERSet(allPaddings)
        val padding: DERTaggedObject =
            DERTaggedObject(true, removeTagType(Constants.KM_TAG_PADDING), paddingSet)
        val noAuthRequired: DERTaggedObject =
            DERTaggedObject(
                true,
                removeTagType(Constants.KM_TAG_NO_AUTH_REQUIRED),
                DERNull.INSTANCE
            )
        // Build sequence
        val allItems: ASN1EncodableVector = ASN1EncodableVector()
        allItems.add(purpose)
        allItems.add(algorithm)
        allItems.add(keySize)
        allItems.add(blockMode)
        allItems.add(padding)
        allItems.add(noAuthRequired)
        return DERSequence(allItems)
    }

    // References:
    // https://cs.android.com/android/platform/superproject/main/+/main:cts/tests/tests/keystore/src/android/keystore/cts/ImportWrappedKeyTest.java
    @RequiresApi(Build.VERSION_CODES.P)
    @kotlin.Throws(Exception::class)
    private fun genKeyPair(alias: String): KeyPair {
        val kpg: KeyPairGenerator =
            KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_RSA,
                Constants.ANDROID_KEY_STORE
            )
        val paramSpec =
            KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or
                        KeyProperties.PURPOSE_DECRYPT or
                        KeyProperties.PURPOSE_SIGN or
                        KeyProperties.PURPOSE_VERIFY or
                        KeyProperties.PURPOSE_WRAP_KEY
            )
                .run {
                    setAlgorithmParameterSpec(
                        RSAKeyGenParameterSpec(
                            Constants.SAMPLE_WRAPPING_RSA_KEY_SIZE,
                            RSAKeyGenParameterSpec.F4
                        )
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
                    build()
                }
        kpg.initialize(paramSpec)
        return kpg.generateKeyPair()
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