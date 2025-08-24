import SwiftUI
import SecretKit
import SecretKitExtensions
import SecureEnclaveSecretKit
import SecureEnclaveSecretKitExtensions
import SmartCardSecretKit
import SmartCardSecretKitExtensions

struct ContentView: View {

    enum Store {
        case secureEnclave
        case smartcard
    }

    @State var selection: Store
    @State var requireAuth = false
    @State var log: String = ""

    var verifyingStore: AnyVerifyingSecretStore {
        switch selection {
        case .secureEnclave:
            AnyVerifyingSecretStore(Self.secureEnclaveStore)
        case .smartcard:
            AnyVerifyingSecretStore(Self.smartcardStore)
        }
    }

    var encryptingStore: AnyEncryptingSecretStore {
        switch selection {
        case .secureEnclave:
            AnyEncryptingSecretStore(Self.secureEnclaveStore)
        case .smartcard:
            AnyEncryptingSecretStore(Self.smartcardStore)
        }
    }

    static let secureEnclaveStore = SecureEnclave.Store()
    static let smartcardStore = SmartCard.Store()

    var body: some View {
        Form {
            Section("Store") {
                Picker("Store", selection: $selection) {
                    Text("Secure Enclave")
                        .tag(Store.secureEnclave)
                    Text("SmartCard")
                        .tag(Store.smartcard)
                }
            }
            Section("Configuration") {
                HStack {
                    Button("Create Secret") {
                        Task {
                            try await Self.secureEnclaveStore.create(name: "Test", requiresAuthentication: requireAuth)
                            appendLog("Created secret")
                        }
                    }
                    Spacer()
                    Toggle("Require Auth", isOn: $requireAuth)
                }
                .disabled(!(selection == .secureEnclave && Self.secureEnclaveStore.secrets.isEmpty))
                Button("Delete Secret") {
                    Task {
                        try await Self.secureEnclaveStore.delete(secret: Self.secureEnclaveStore.secrets.first!)
                        appendLog("Deleted secret")
                    }
                }
                .disabled(!(selection == .secureEnclave && !Self.secureEnclaveStore.secrets.isEmpty))
            }
            Section("Test") {
                Group {
                    Button("Test Encrypt/Decrypt Roundtrip") {
                        Task {
                            let secret = encryptingStore.secrets[0]
                            let start = Data("Hello World".utf8)
                            appendLog("Encrypting: \(start.base64EncodedString())")
                            let encrypted = try await encryptingStore.encrypt(data: start, with: secret)
                            appendLog("Encrypted: \(encrypted.base64EncodedString())")
                            let decrypted = try await encryptingStore.decrypt(data: encrypted, with: secret)
                            appendLog("Decrypted: \(decrypted.base64EncodedString())")
                            appendLog("Good: \(start == decrypted)")
                        }
                    }
                    .disabled(encryptingStore.secrets.isEmpty)
                    Button("Test Sign/Verify Roundtrip") {
                        Task {
                            let secret = verifyingStore.secrets.first!
                            let start = Data("Hello World".utf8)
                            appendLog("Signing: \(start.base64EncodedString())")
                            let signature = try await verifyingStore.sign(data: start, with: secret, for: .demo)
                            appendLog("Signature: \(signature.base64EncodedString())")
                            let verified = try await verifyingStore.verify(signature: signature, for: start, with: secret)
                            appendLog("Verified: \(verified)")
                        }

                    }
                    .disabled(verifyingStore.secrets.isEmpty)
                }
            }
            Section("Log") {
                TextEditor(text: $log)
                    .disabled(true)
            }
        }
        .formStyle(.grouped)
    }

    @MainActor func appendLog(_ text: String) {
        log.append("\(text)\n\n")
    }

}

extension SigningRequestProvenance {
    static var demo: SigningRequestProvenance {
        .init(root: .init(pid: 0, processName: "Test", appName: nil, iconURL: nil, path: "/", validSignature: true, parentPID: 0))
    }
}
