import Foundation
import CryptoKit

class SecureEnclaveInspector {
    @available(iOS 13.0, *)
    func hasSecureEnclave() throws -> Bool {
        let isSecureEnclaveSupported = SecureEnclave.isAvailable
        guard isSecureEnclaveSupported == true else {
            return false
        }
        return isSecureEnclaveSupported
    }
}