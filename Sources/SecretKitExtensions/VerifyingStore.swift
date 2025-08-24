import Foundation
import SecretKit

public protocol VerifyingSecretStore: SecretStore {

    /// Verifies that a signature is valid over a specified payload.
    /// - Parameters:
    ///   - signature: The signature over the data.
    ///   - data: The data to verify the signature of.
    ///   - secret: The secret whose signature to verify.
    /// - Returns: Whether the signature was verified.
    func verify(signature: Data, for data: Data, with secret: SecretType) async throws -> Bool

}

extension VerifyingSecretStore {

    public func verify(signature: Data, for data: Data, with secret: SecretType) async throws -> Bool {
        let attributes = KeychainDictionary([
            kSecAttrKeyType: secret.algorithm.secAttrKeyType,
            kSecAttrKeySizeInBits: secret.keySize,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
        ])
        var verifyError: SecurityError?
        let untyped: CFTypeRef? = SecKeyCreateWithData(secret.publicKey as CFData, attributes, &verifyError)
        guard let untypedSafe = untyped else {
            throw KeychainError(statusCode: errSecSuccess)
        }
        let key = untypedSafe as! SecKey
        let verified = SecKeyVerifySignature(key, try signatureAlgorithm(for: secret, allowRSA: true), data as CFData, signature as CFData, &verifyError)
        if !verified, let verifyError {
            if verifyError.takeUnretainedValue() ~= .verifyError {
                return false
            } else {
                throw SigningError(error: verifyError)
            }
        }
        return verified
    }

}
