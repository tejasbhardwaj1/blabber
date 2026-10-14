// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Blabber",
    platforms: [.macOS("26.0")],
    targets: [
        // Pure logic + system-integration layers (hotkey, audio, speech,
        // formatting, injection, permissions) with no app-lifecycle code.
        // Split out so it can be linked from both the app executable and
        // the SelfCheck runner — an executableTarget cannot be linked
        // against by another target, only a library can.
        .target(
            name: "BlabberCore",
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .unsafeFlags(["-enable-testing"]),
            ]
        ),
        .executableTarget(
            name: "Blabber",
            dependencies: ["BlabberCore"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        // Standalone fallback test runner — see Sources/SelfCheck/main.swift
        // for why `swift test` isn't usable on this CLT-only toolchain.
        .executableTarget(
            name: "SelfCheck",
            dependencies: ["BlabberCore"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "BlabberTests",
            dependencies: ["BlabberCore"],
            swiftSettings: [
                .unsafeFlags([
                    "-Fsystem", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                ])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Fsystem", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/usr/lib",
                ])
            ]
        ),
    ]
)
