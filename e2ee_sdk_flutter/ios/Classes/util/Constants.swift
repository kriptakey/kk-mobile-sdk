import Foundation

enum KMSException: Error {
    case secureEnclaveNotSupported(String)
    case keyNotFound(String)
    case csrGenerationFailed(String)
    case keyExisted(String)
    case generateRandomFailed(String)
    case aesKeyGenerationFailed(String)
    case encryptionFailed(String)
    case importAesKeyFailed(String)
    case algorithmNotSupported(String)
    case keyDeletionFailed(String)
    case localAuthenticationNotSupported(String)
    case platformNotSupported(String)
    case ecKeyGenerationFailed(String)
    case generateSignatureFailed(String)
}