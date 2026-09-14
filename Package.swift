// swift-tools-version:6.0
import PackageDescription

// NOTE: `swift test` is unusable with Command Line Tools alone (no XCTest; the
// shipped Testing.framework silently discovers zero tests). Tests are a plain
// executable instead: `swift run RelayTests` — exits non-zero on failure.
let package = Package(
    name: "Relay",
    platforms: [.macOS(.v15)],
    targets: [
        .target(name: "RelayCore"),
        .executableTarget(name: "Relay", dependencies: ["RelayCore"]),
        .executableTarget(name: "RelayTests", dependencies: ["RelayCore"], path: "Tests/RelayTests"),
    ],
    swiftLanguageModes: [.v5]
)
