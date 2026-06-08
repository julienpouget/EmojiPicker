// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "EmojiPicker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "EmojiPicker",
            targets: ["EmojiPicker"]
        ),
    ],
    targets: [
        .target(
            name: "EmojiPicker",
            resources: [
                .process("Resources/emojis.json"),
            ]
        ),
        .testTarget(
            name: "EmojiPickerTests",
            dependencies: ["EmojiPicker"]
        ),
    ]
)
