import Foundation
import CommonCrypto
import SCCSR
import LocalAuthentication
import CryptoKit

class Crypto {
    @available(iOS 13.0, *)
    public func generateECP256Keypair(
        keyAlias: String,
        requireAuth: Bool,
        allowOverwrite: Bool 
    ) throws -> Void {
        let isSecureEnclaveSupported = try? SecureEnclaveInspector().hasSecureEnclave()
        if (!isSecureEnclaveSupported!) {
            throw KMSException.secureEnclaveNotSupported("Secure enclave not supported.")
        }

        // Verify whether the key is already available
        let devicePrivateKey = try? getKey(keyAlias: keyAlias);
        if (devicePrivateKey != nil && !allowOverwrite) {
            throw KMSException.keyExisted("The key already exists.")
        } else if (devicePrivateKey != nil && allowOverwrite) {
            do {
                try deleteKeyFromSecureEnclave(keyAlias: keyAlias)
            } catch {
                throw KMSException.keyDeletionFailed("Key deletion failed.")
            }
        }

        // TODO: Test with actual device to demonstrate the access control
        let flags: SecAccessControlCreateFlags

        if #available(iOS 11.3, *) {
            if (requireAuth) {
                flags = [.userPresence]
            } else {
                flags = [.privateKeyUsage]
            }
        } else if (requireAuth) {
            throw KMSException.localAuthenticationNotSupported("Local authentication not supported.")
        } else {
            throw KMSException.platformNotSupported("Platform is not supported.")
        }

        var error: Unmanaged<CFError>?
        let access = SecAccessControlCreateWithFlags(
            nil, 
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly, 
            flags, &error)!

        let attributes: NSDictionary = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: keyAlias,
                kSecAttrAccessControl: access
            ]
        ]

        var errorTwo: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes, &errorTwo) else {
            throw errorTwo!.takeRetainedValue() as Error
        }
    }

    public func generateApplicationCSR(
        keyAlias: String,
        commonName: String,
        country: String,
        location: String,
        state: String,
        organizationName: String,
        organizationUnit: String
    ) throws -> String? {
        let ecPrivateKey: SecKey?
        do {
            ecPrivateKey = try getKey(keyAlias: keyAlias)
        } catch {
            throw KMSException.keyNotFound("Key does not exist.")
        }

        let ecPublicKey = SecKeyCopyPublicKey(ecPrivateKey!)
        let csrAttributes = SCCSRAttributes(
            commonName: commonName,
            organization: organizationName,
            organizationUnit: organizationUnit,
            country: country,
            stateOrProvince: state,
            locality: location
        )

        var applicationCsr:String = "csrInitialization"

        SCCSRHelper.generateCSR(
            from: ecPrivateKey!,
            publicKey: ecPublicKey!,
            attributes: csrAttributes,
            with: KeyAlgorithm.ec(signatureType: .sha512)) {
                (csr, error) -> Void in 
                if (csr != nil) {
                    applicationCsr = csr!
                } else {
                    return
                }
            }
        if (applicationCsr != "csrInitialization") {
            return applicationCsr
        }
        return applicationCsr
    }

    @available(iOS 13.0, *)
    public func generateAES256Key(
        keyAlias: String,
        requireAuth: Bool,
        allowOverwrite: Bool
    ) throws -> Void {
        // TODO: Test with actual mobile device to demonstrate the access control
        let context = LAContext()
        context.localizedReason = "Access device based password from iOS Keychain"
        
        // TODO: Test with actual device to demonstrate the access control
        var error: Unmanaged<CFError>?
        let access = SecAccessControlCreateWithFlags(nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .userPresence, &error)

        // Define retrieving query
        let retrieveQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyAlias,
            kSecUseDataProtectionKeychain as String: true,
            kSecUseAuthenticationContext as String: context,
            kSecAttrAccessControl as String: access as Any,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true] as [String: Any]

        // Define deleting query
        let deletingQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyAlias,
            kSecUseDataProtectionKeychain as String: true,
            kSecUseAuthenticationContext as String: context,
            kSecAttrAccessControl as String: access as Any,
            kSecReturnData as String: true] as [String: Any]

        let symmetricKey = try? getSymmetricKeyFromKeychain(keyAlias: keyAlias, query: retrieveQuery)
        if (symmetricKey != nil && allowOverwrite) {
            do {
                try deleteKeyFromKeychain(keyAlias: keyAlias, query: retrieveQuery)
            } catch {
                throw KMSException.keyDeletionFailed("Key deletion failed.")
            }
        } else if (symmetricKey != nil) {
            throw KMSException.keyExisted("Key already exists.")
        }

        // Create a new AES key
        var randomBytes = [Int8](repeating: 0, count: 32)
        let generateRandomBytesStatus = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if generateRandomBytesStatus != errSecSuccess { 
            throw KMSException.generateRandomFailed("Random generation failed.")
        }

        // Treat the key data as a generic password.
        var addQuery: [String: Any] = [String: Any]()
        if (requireAuth) {
            addQuery = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: keyAlias,
                kSecUseDataProtectionKeychain: true,
                kSecAttrAccessControl: access as Any,
                kSecUseAuthenticationContext: context,
                kSecValueData: Data(bytes: randomBytes, count: 32)] as [String: Any]
        } else {
               addQuery = [kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: keyAlias,
                kSecUseDataProtectionKeychain: true,
                kSecValueData: Data(bytes: randomBytes, count: 32)] as [String: Any]
        }

        // Add the key data.
        let addKeyStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addKeyStatus == errSecSuccess else {
            throw KMSException.aesKeyGenerationFailed("AES key generation failed.")
        }
    }

    @available(iOS 13.0, *)
    public func encryptAES256GCM(keyAlias: String, plainData: Data, iv: Data, aad: Data?) throws -> Data? {
        // TODO: Test with actual device to demonstrate the access control
        let context = LAContext()
        context.localizedReason = "Access device based password from iOS Keychain"
        
        // TODO: Test with actual device to demonstrate the access control
        var error: Unmanaged<CFError>?
        let access = SecAccessControlCreateWithFlags(nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .userPresence, &error)

        // Define retrieving query
        let retrieveQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyAlias,
            kSecUseDataProtectionKeychain as String: true,
            kSecUseAuthenticationContext as String: context,
            kSecAttrAccessControl as String: access as Any,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true] as [String: Any]
                
        let symmetricKey = try? getSymmetricKeyFromKeychain(keyAlias: keyAlias, query: retrieveQuery)
        if (symmetricKey == nil) {
            throw KMSException.keyNotFound("Key does not exist")
        }

        var ciphertext: Data?
        var sealedBox: AES.GCM.SealedBox?
        do {
            if (aad != nil) {
                sealedBox = try AES.GCM.seal(plainData, using: symmetricKey!, nonce: AES.GCM.Nonce(data: iv), 
                authenticating: aad!)
            } else {
                sealedBox = try AES.GCM.seal(plainData, using: symmetricKey!, nonce: AES.GCM.Nonce(data: iv))
            }
            ciphertext = sealedBox!.combined
            return ciphertext!
        } catch {
            throw KMSException.encryptionFailed("AES encryption failed.")
        }
    }

    public func signData(keyAlias: String, plainData: Data) throws -> Data? {
        let privateKey: SecKey?
        do {
            privateKey = try getKey(keyAlias: keyAlias)
        } catch {
            throw KMSException.keyNotFound("Key does not exist.")
        }
        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA512

        guard SecKeyIsAlgorithmSupported(privateKey!, .sign, algorithm) else {
            throw KMSException.algorithmNotSupported("Algorithm is not supported.")
        }
        
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey!,
            algorithm,
            plainData as CFData,
            &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        return signature
    }

    @available(iOS 13.0, *)
    public func importAES256GCMKey(
          keyAlias: String,
          wrappedKey: Data,
          allowOverwrite: Bool
        ) throws -> Void {
            // TODO: Test with actual device to demonstrate the access control
            let context = LAContext()
            context.localizedReason = "Access device based password from iOS Keychain"
            
            // TODO: Test with actual device to demonstrate the access control
            var error: Unmanaged<CFError>?
            let access = SecAccessControlCreateWithFlags(nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .userPresence, &error)

            // Define retrieving query
            let retrieveQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keyAlias,
                kSecUseDataProtectionKeychain as String: true,
                kSecUseAuthenticationContext as String: context,
                kSecAttrAccessControl as String: access as Any,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecReturnData as String: true] as [String: Any]

            let symmetricKey = try? getSymmetricKeyFromKeychain(keyAlias: keyAlias, query: retrieveQuery)
            if (symmetricKey != nil && allowOverwrite) {
                do {
                    try deleteKeyFromKeychain(keyAlias: keyAlias, query: retrieveQuery)
                } catch {
                    throw KMSException.keyDeletionFailed("Key deletion failed.")
                }
            } else if (symmetricKey != nil) {
                throw KMSException.keyExisted("Key already exists.")
            }

            // Treat the key data as a generic password.
            var addQuery: [String: Any] = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccount: keyAlias,
                    kSecUseDataProtectionKeychain: true,
                    kSecAttrAccessControl: access as Any,
                    kSecUseAuthenticationContext: context,
                    kSecValueData: wrappedKey] as [String: Any]

            // Add the key data.
            let addKeyStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addKeyStatus == errSecSuccess else {
                throw KMSException.importAesKeyFailed("Import AES key failed.")
            }
        }

    @available(iOS 13.0, *)
    public func deleteAES256GCMkey(keyAlias: String) throws -> Void {
        // Define retrieving query
        let retrieveQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyAlias,
            kSecUseDataProtectionKeychain as String: true,
            kSecUseAuthenticationContext as String: context,
            kSecAttrAccessControl as String: access as Any,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true] as [String: Any]

         let symmetricKey = try? getSymmetricKeyFromKeychain(keyAlias: keyAlias, query: retrieveQuery)
        if (symmetricKey != nil) {
            do {
                try deleteKeyFromKeychain(keyAlias: keyAlias, query: retrieveQuery)
            } catch {
                throw KMSException.keyDeletionFailed("Key deletion failed.")
            }
        }
    }

    @available(iOS 13.0, *)
    public func deleteKeyPair(keyAlias: String) throws -> Void {
        // Verify whether the key is already available
        let privateKey = try? getKey(keyAlias: keyAlias);
        if (privateKey != nil) {
            do {
                try deleteKeyFromSecureEnclave(keyAlias: keyAlias)
            } catch {
                throw KMSException.keyDeletionFailed("Key deletion failed.")
            }
        }
    }

    private func getKey(keyAlias: String) throws -> SecKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        var keyItem: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &keyItem)
        guard status == errSecSuccess else {
            throw KMSException.keyNotFound("Key does not exist.")
        }
        return keyItem as! SecKey
    }

    @available(iOS 13.0, *)
    private func getSymmetricKeyFromKeychain(keyAlias: String, query: [String: Any]) throws -> SymmetricKey? {
        var item: CFTypeRef?
        switch SecItemCopyMatching(query as CFDictionary, &item) {
            case errSecSuccess:
                guard let data = item as? Data else { return nil }
                return SymmetricKey(data: data)
            case errSecItemNotFound:
                throw KMSException.keyNotFound("Key does not exist.")
            default: 
                throw KMSException.keyNotFound("Key does not exist.")
        }
    }

    private func deleteKeyFromKeychain(keyAlias: String, query: [String: Any]) throws -> Void {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { 
            throw KMSException.keyNotFound("Key does not exist.") }
    }

    private func deleteKeyFromSecureEnclave(keyAlias: String) throws -> Void {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { 
            throw KMSException.keyDeletionFailed("Key deletion failed.") }
    }
}