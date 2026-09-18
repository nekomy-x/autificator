// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Autificator",
    platforms: [.macOS("14.0")],
    products: [
        .executable(name: "Autificator", targets: ["App"])
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [],
            path: "Sources",
            sources: ["main.swift", "AppDelegate.swift", "Account.swift", "TOTPGenerator.swift", "KeychainManager.swift", "AccountsManager.swift", "ContentView.swift", "AccountRowView.swift", "AddAccountSheet.swift"]
        )
    ]
)