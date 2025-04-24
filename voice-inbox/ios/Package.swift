// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "VoiceInbox",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "VoiceInbox",
            targets: ["VoiceInbox"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1"),
        .package(url: "https://github.com/openai/openai-swift.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "VoiceInbox",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "OpenAI", package: "openai-swift")
            ],
            path: "VoiceInbox"),
        .testTarget(
            name: "VoiceInboxTests",
            dependencies: ["VoiceInbox"],
            path: "VoiceInboxTests"),
    ]
) 