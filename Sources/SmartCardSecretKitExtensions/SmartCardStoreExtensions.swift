import Foundation
import SecretKit
import SecretKitExtensions
import SmartCardSecretKit
import LocalAuthentication

extension SmartCard.Store: VerifyingSecretStore {}

extension SmartCard.Store: EncryptingSecretStore {

    /// - Warning; Certain smart cards allow you to _encrypt_ data with certain kinds of keys (eg, signing keys) but do not support decryption operations.
    /// to prevent users from accidentally encrypting data they can't later decrypt, this implementation first attempts to decrypt the encrypted data before returning the encrypted data.
    /// This will present a popup requesting authorization. If you're POSITIVE that the key supports decryption and wish to bypass this, call `encryptWithoutValidation`.
    public func encrypt(data: Data, with secret: SecretType) async throws -> Data {
        let encrypted = try await _encrypt(data: data, with: secret)
        do {
            _ = try await _decrypt(data: encrypted, with: secret, verification: true)
            return encrypted
        } catch {
            throw KeyDoesNotSupportDecryptionError()
        }

    }

    /// - Warning: See `encrypt` for discussion of when to call this method.
    public func encryptWithoutValidation(data: Data, with secret: SecretType) async throws -> Data {
        try await _encrypt(data: data, with: secret)
    }

    public func decrypt(data: Data, with secret: SecretType) async throws -> Data {
        try await _decrypt(data: data, with: secret, verification: false)
    }

    private func _decrypt(data: Data, with secret: SecretType, verification: Bool) async throws -> Data {
        guard let tokenID = await smartcardTokenID else { fatalError() }
        let context = LAContext()
        if verification {
            context.localizedReason = String(localized: .authContextRequestEncryptDescription(secretName: secret.name))
        } else {
            context.localizedReason = String(localized: .authContextRequestDecryptDescription(secretName: secret.name))
        }
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
        guard let decrypted = SecKeyCreateDecryptedData(key, try encryptionAlgorithm(for: secret), data as CFData, &encryptError) else {
            throw EncryptionError(error: encryptError)
        }
        return decrypted as Data
    }

}

public struct KeyDoesNotSupportDecryptionError: Error {

}
