import Foundation
import SecretKit
import SecretKitExtensions
import SmartCardSecretKit
import LocalAuthentication

extension SmartCard.Store: StoreEncrypable {

    public func decrypt(data: Data, with secret: SecretType, for provenance: SigningRequestProvenance) async throws -> Data {
        guard let tokenID = await smartcardTokenID else { fatalError() }
        let context = LAContext()
        context.localizedReason = String(localized: .authContextRequestDecryptDescription(secretName: secret.name))
        context.localizedCancelTitle = String(localized: .authContextRequestDenyButton)
        let attributes = KeychainDictionary([
            kSecClass: kSecClassKey,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrApplicationLabel: secret.id as CFData,
            kSecAttrTokenID: tokenID,
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
        guard let signature = SecKeyCreateDecryptedData(key, try encryptionAlgorithm(for: secret), data as CFData, &encryptError) else {
            throw EncryptionError(error: encryptError)
        }
        return signature as Data
    }

}


