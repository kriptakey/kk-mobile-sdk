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
        const val DIGEST_SIGNATURE_ALGORITHM = "NONEwithECDSA"
    }
}

class KMSException(message: String? = null, cause: Throwable? = null) : Exception(message, cause)