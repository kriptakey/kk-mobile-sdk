package com.klaviskripta.e2ee_sdk_flutter.util

class ErrorCode {
    companion object {
        // Crypto
        const val AES_256_GCM_ENCRYPTION_FAILED: Int = 2000000
        const val CSR_GENERATION_FAILED: Int = 2000010
        const val AES_256_GCM_DECRYPTION_FAILED: Int = 2000011
        const val RSA_DECRYPTION_FAILED: Int = 2000012
        const val AES_KEY_GENERATION_FAILED: Int = 2000013
        const val EC_KEY_PAIR_GENERATION_FAILED: Int = 2000014
        const val RSA_KEY_PAIR_GENERATION_FAILED: Int = 2000015
        const val IMPORT_AES_256_GCM_KEY_GENERATION_FAILED: Int = 2000016
        const val KEY_DELETION_FAILED: Int = 2000017

        // Secure environment or strong box
        const val SECURE_ENVIRONMENT_UNAVAILABLE: Int = 3000000
        const val STRONG_BOX_UNAVAILABLE: Int = 3000001
        const val SECURE_KEY_IMPORT_UNAVAILABLE: Int = 3000002

        // Key availability
        const val KEY_NOT_FOUND: Int = 5000001
    }
}