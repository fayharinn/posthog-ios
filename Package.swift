// swift-tools-version:5.3
// PATCHED: Use SDWebImage's libwebp instead of bundled phlibwebp to avoid duplicate symbols
import PackageDescription

let package = Package(
    name: "PostHog",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6),
    ],
    products: [
        .library(
            name: "PostHog",
            targets: ["PostHog"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", from: "6.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "12.0.0"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", from: "9.0.0"),
        // Use SDWebImage's libwebp (same one Kingfisher uses)
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.54.0"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.54.0"),
        .package(url: "https://github.com/SDWebImage/libwebp-Xcode.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "PostHog",
            dependencies: [
                .product(name: "libwebp", package: "libwebp-Xcode")
            ],
            path: "PostHog",
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy"),
            ]
        ),
        .testTarget(
            name: "PostHogTests",
            dependencies: [
                "PostHog",
                "Quick",
                "Nimble",
                "OHHTTPStubs",
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
            ],
            path: "PostHogTests",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
