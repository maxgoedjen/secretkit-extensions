import Foundation
import SecretKit


/// A signing-related error.
public struct EncryptionError: Error {
    /// The underlying error reported by the API, if one was returned.
    public let error: SecurityError?

    /// Initializes a EncryptionError with an optional SecurityError.
    /// - Parameter statusCode: The SecurityError, if one is applicable.
    public init(error: SecurityError?) {
        self.error = error
    }

}
