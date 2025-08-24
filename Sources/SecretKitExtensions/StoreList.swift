import Foundation
import Observation
import SecretKit

/// A "Store Store," which holds a list of type-erased stores.
@Observable @MainActor public final class ExtendedSecretStoreList: Sendable {

    let backing = SecretStoreList()

    /// Initializes an ExtendedSecretStoreList.
    public nonisolated init() {
    }

    /// Adds a non-type-erased SecretStore to the list.
    public func add<SecretStoreType: SecretStore>(store: SecretStoreType) {
        backing.add(store: store)
    }

    /// Adds a non-type-erased modifiable SecretStore.
    public func add<SecretStoreType: SecretStoreModifiable>(store: SecretStoreType) {
        backing.add(store: store)
    }

    /// A boolean describing whether there are any Stores available.
    public var anyAvailable: Bool {
        backing.anyAvailable
    }

    public var allSecrets: [AnySecret] {
        backing.allSecrets
    }

}
