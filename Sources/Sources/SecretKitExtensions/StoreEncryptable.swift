import Foundation
import SecretKit

public protocol StoreEncrypable: SecretStore {

    /// Encrypts a payload with a specified key.
    /// - Parameters:
    ///   - data: The payload to encrypt.
    ///   - secret: The secret to encrypt with.
    /// - Returns: The encrypted data.
    func encrypt(data: Data, with secret: SecretType, for provenance: SigningRequestProvenance) async throws -> Data

    /// Decrypts a payload with a specified key.
    /// - Parameters:
    ///   - data: The payload to decrypt.
    ///   - secret: The secret to decrypt with.
    /// - Returns: The decrypted data.
    func decrypt(data: Data, with secret: SecretType, for provenance: SigningRequestProvenance) async throws -> Data

}

extension StoreEncrypable {

    public func encrypt(data: Data, with secret: SecretType, for provenance: SigningRequestProvenance) throws -> Data {
        let attributes = KeychainDictionary([
            kSecAttrKeyType: secret.algorithm.secAttrKeyType,
            kSecAttrKeySizeInBits: secret.keySize,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
        ])
        var encryptError: SecurityError?
        let untyped: CFTypeRef? = SecKeyCreateWithData(secret.publicKey as CFData, attributes, &encryptError)
        guard let untypedSafe = untyped else {
            throw KeychainError(statusCode: errSecSuccess)
        }
        let key = untypedSafe as! SecKey
        guard let signature = SecKeyCreateEncryptedData(key, try encryptionAlgorithm(for: secret), data as CFData, &encryptError) else {
            throw EncryptionError(error: encryptError)
        }
        return signature as Data
    }

    package func encryptionAlgorithm(for secret: SecretType) throws -> SecKeyAlgorithm {
        switch (secret.algorithm, secret.keySize) {
        case (.ellipticCurve, 256):
            return .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        case (.ellipticCurve, 384):
            return .eciesEncryptionCofactorVariableIVX963SHA384AESGCM
        case (.rsa, 1024), (.rsa, 2048):
            return .rsaEncryptionOAEPSHA512AESGCM
        default:
            throw UnsupportedKeyType()
        }
    }

}

public struct UnsupportedKeyType: Error {}
