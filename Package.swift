// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "swift-acoustics",
    platforms: [.macOS(.v27), .iOS(.v27), .tvOS(.v27), .watchOS(.v27), .visionOS(.v27)],
    products: [.library(name: "Acoustics", targets: ["Acoustics"])],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-bessel.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-cardinal.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-numeric.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Acoustics",
            dependencies: [
                .product(name: "Bessel", package: "swift-bessel"),
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Numeric", package: "swift-numeric"),
            ]
        ),
        .testTarget(
            name: "Acoustics Tests",
            dependencies: [
                .target(name: "Acoustics")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
