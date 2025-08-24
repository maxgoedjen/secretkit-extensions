// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SecretKitExtensionPackages",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SecretKitExtensions",
            targets: ["SecretKitExtensions"]),
        .library(
            name: "SecureEnclaveSecretKitExtensions",
            targets: ["SecureEnclaveSecretKitExtensions"]),
        .library(
            name: "SmartCardSecretKitExtensions",
            targets: ["SmartCardSecretKitExtensions"]),
    ],
    dependencies: [
        .package(url: "https://github.com/maxgoedjen/secretive", branch: "layout"),
    ],
    targets: [
        .target(
            name: "SecretKitExtensions",
            dependencies: [.product(name: "SecretKit", package: "secretive")],
            resources: [localization],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SecureEnclaveSecretKitExtensions",
            dependencies: [.product(name: "SecureEnclaveSecretKit", package: "secretive"), "SecretKitExtensions"],
            resources: [localization],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SmartCardSecretKitExtensions",
            dependencies: [.product(name: "SmartCardSecretKit", package: "secretive"), "SecretKitExtensions"],
            resources: [localization],
            swiftSettings: swiftSettings
        ),
    ]
)

var localization: Resource {
    .process("../../Localizable.xcstrings")
}

var swiftSettings: [PackageDescription.SwiftSetting] {
    [
        .swiftLanguageMode(.v6),
        .treatAllWarnings(as: .error),
    ]
}
