import Foundation
import SecretKit
import SecretKitExtensions
import SecureEnclaveSecretKit
import LocalAuthentication

extension SecureEnclave.Store: VerifyingSecretStore {}

extension SecureEnclave.Store: EncryptingSecretStore {

    public func decrypt(data: Data, with secret: SecretType) async throws -> Data {
        let context = LAContext()
        context.localizedCancelTitle = String(localized: .authContextRequestDenyButton)
        context.localizedReason = String(localized: .authContextRequestDecryptDescription(secretName: secret.name))
        let attributes = KeychainDictionary([
            kSecClass: kSecClassKey,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrApplicationLabel: secret.id as CFData,
            kSecAttrKeyType: SecureEnclave.Constants.keyType,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecAttrApplicationTag: SecureEnclave.Constants.keyTag,
            kSecUseAuthenticationContext: context,
            kSecReturnRef: true
        ])
        var untyped: CFTypeRef?
        let status = SecItemCopyMatching(attributes, &untyped)
        if status != errSecSuccess {
            throw KeychainError(statusCode: status)
        }
        guard let untypedSafe = untyped else {
            throw KeychainError(statusCode: errSecSuccess)
        }
        let key = untypedSafe as! SecKey
        var encryptError: SecurityError?
        guard let decrypted = SecKeyCreateDecryptedData(key, try encryptionAlgorithm(for: secret), data as CFData, &encryptError) else {
            throw SigningError(error: encryptError)
        }
        return decrypted as Data
    }

}
