// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EmojiAI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "EmojiAI",
            targets: ["EmojiAI"]
        ),
        .library(
            name: "EmojiAICore",
            targets: ["EmojiAICore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EmojiAICore",
            dependencies: [],
            path: "Sources/EmojiAICore",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "EmojiAI",
            dependencies: ["EmojiAICore"],
            path: "Sources/EmojiAI"
        ),
        .testTarget(
            name: "EmojiAITests",
            dependencies: ["EmojiAICore"],
            path: "Tests/EmojiAITests"
        )
    ]
)
