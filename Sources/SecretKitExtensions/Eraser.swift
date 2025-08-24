import Foundation
import SecretKit

/// Type eraser for SecretStore.

public final class AnyVerifyingSecretStore: AnySecretStore, VerifyingSecretStore, @unchecked Sendable {

    private let _verify: @Sendable (Data, Data, AnySecret) async throws -> Bool

    public init<SecretStoreType>(_ secretStore: SecretStoreType) where SecretStoreType: VerifyingSecretStore {
        _verify = { try await secretStore.verify(signature: $0, for: $1, with: $2.base as! SecretStoreType.SecretType) }
        super.init(secretStore)
    }

    public func verify(signature: Data, for data: Data, with secret: AnySecret) async throws -> Bool {
        try await _verify(signature, data, secret)
    }

}


public final class AnyEncryptingSecretStore: AnySecretStore, EncryptingSecretStore, @unchecked Sendable {

    private let _encrypt: @Sendable (Data, AnySecret) async throws -> Data
    private let _decrypt: @Sendable (Data, AnySecret) async throws -> Data

    public init<SecretStoreType>(_ secretStore: SecretStoreType) where SecretStoreType: EncryptingSecretStore {
        _encrypt = { try await secretStore.encrypt(data: $0, with: $1.base as! SecretStoreType.SecretType) }
        _decrypt = { try await secretStore.decrypt(data: $0, with: $1.base as! SecretStoreType.SecretType) }
        super.init(secretStore)
    }

    public func encrypt(data: Data, with secret: AnySecret) async throws -> Data {
        try await _encrypt(data, secret)
    }

    public func decrypt(data: Data, with secret: AnySecret) async throws -> Data {
        try await _decrypt(data, secret)
    }


}
