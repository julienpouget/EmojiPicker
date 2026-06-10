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
                .process("Resources/Localizable.xcstrings"),
                // Privacy manifest: must keep its exact name at the bundle
                // root for Xcode's privacy-report aggregation, hence `.copy`.
                .copy("Resources/PrivacyInfo.xcprivacy"),
            ]
        ),
        .testTarget(
            name: "EmojiPickerTests",
            dependencies: ["EmojiPicker"]
        ),
    ]
)
