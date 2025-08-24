import Foundation
import SecretKit

public protocol StoreVerifiable: SecretStore {

    /// Verifies that a signature is valid over a specified payload.
    /// - Parameters:
    ///   - signature: The signature over the data.
    ///   - data: The data to verify the signature of.
    ///   - secret: The secret whose signature to verify.
    /// - Returns: Whether the signature was verified.
    func verify(signature: Data, for data: Data, with secret: SecretType, for provenance: SigningRequestProvenance) async throws -> Bool

}

extension StoreVerifiable {

    public func verify(signature: Data, for data: Data, with secret: SecretType, for provenance: SigningRequestProvenance) throws -> Bool {
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
        let verified = SecKeyVerifySignature(key, .ecdsaSignatureMessageX962SHA256, data as CFData, signature as CFData, &verifyError)
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
