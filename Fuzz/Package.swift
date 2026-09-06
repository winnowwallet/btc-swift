// swift-tools-version: 6.0
import PackageDescription

// A separate package exercises public products from this checkout without
// adding the harness to the production package or resolving another branch.
let package = Package(
    name: "btc-swift-fuzz",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "WinnowFuzz", targets: ["WinnowFuzz"]),
    ],
    dependencies: [.package(name: "btc-swift", path: "..")],
    targets: [
        .executableTarget(
            name: "WinnowFuzz",
            dependencies: [
                .product(name: "BitcoinCore", package: "btc-swift"),
                .product(name: "BitcoinP2P", package: "btc-swift"),
                .product(name: "WalletCore", package: "btc-swift"),
            ]
        ),
    ]
)
