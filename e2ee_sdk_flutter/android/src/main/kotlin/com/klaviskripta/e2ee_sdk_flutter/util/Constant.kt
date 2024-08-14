package com.klaviskripta.e2ee_sdk_flutter.util

class Constants {
    companion object {
        const val ANDROID_KEY_STORE : String = "AndroidKeyStore"
        const val SAMPLE_KEY_PAIR : String = "SampleKeyPair"
        const val SIGNATURE_ALGORITHM = "SHA512withECDSA"
        const val AES_CIPHER_MODE = "AES/GCM/NoPadding"
        const val RSA_CIPHER_MODE = "RSA/ECB/OAEPPadding"
        const val EC_GEN_PARAMETER_SPEC = "secp256r1"
        const val RSA_OAEP_HASH_PARAMETER_SPEC = "SHA-256"
        const val RSA_OAEP_MGF1_PARAMETER_SPEC = "MGF1"
        const val AES_KEY_SIZE: Int = 256
        const val AUTHENTICATION_TAG_LENGTH : Int = 128
        const val USER_VALIDITY_DURATION : Int = 5 * 60
        const val USER_AUTHENTICATED_DURATION : Int = 2 * 60
        const val NODIGEST_SIGNATURE_ALGORITHM = "NONEwithECDSA"
        const val AES_ALGO_STRING: String = "AES"
        const val SAMPLE_WRAPPING_KEY_ALIAS: String = "SampleWrappingKeyAlias"
        const val SAMPLE_AES_KEY_ALIAS: String = "SampleKeyAES"
        const val SECRET_KEY_PASSWORD_PROTECTION: String = "SecretKeyPassword"
        const val SAMPLE_WRAPPING_RSA_KEY_SIZE: Int = 3072

        // Android keymaster tag types
        // References
        // https://android.googlesource.com/platform/frameworks/base/+/45d2783/core/java/android/security/keymaster/KeymasterDefs.java
        const val KM_ENUM: Int = 1 shl 28
        const val KM_ENUM_REP: Int = 2 shl 28
        const val KM_UINT: Int = 3 shl 28
        const val KM_BOOL: Int = 7 shl 28

        // Android keymaster key formats
        const val KM_KEY_FORMAT_RAW: Long = 3

        // Android keymaster algorithm values
        const val KM_ALGORITHM_AES: Long = 32

        // Android keymaster operation purposes
        const val KM_PURPOSE_ENCRYPT: Long = 0
        const val KM_PURPOSE_DECRYPT: Long = 1

        // Android keymaster tag values
        const val KM_TAG_PURPOSE: Int = KM_ENUM_REP or 1
        const val KM_TAG_ALGORITHM: Int = KM_ENUM or 2
        const val KM_TAG_KEY_SIZE: Int = KM_UINT or 3
        const val KM_TAG_BLOCK_MODE: Int = KM_ENUM_REP or 4
        const val KM_TAG_PADDING: Int = KM_ENUM_REP or 6
        const val KM_TAG_NO_AUTH_REQUIRED: Int = KM_BOOL or 503

        // Android keymaster block modes
        const val KM_MODE_CBC: Long = 2
        const val KM_MODE_ECB: Long = 1

        // Android keymaster padding modes
        const val KM_PAD_NONE: Long = 1
        const val KM_PAD_PKCS7: Long = 64
    }
}

class KMSException(message: String? = null, cause: Throwable? = null) : Exception(message, cause)