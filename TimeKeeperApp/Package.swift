// swift-tools-version: 5.9
//
// TimeKeeper — shared library package.
// The runnable @main app lives in Sources/TimeKeeperApp and is meant to be
// dropped into an Xcode multiplatform App target (see OPEN_IN_XCODE.md).
// This package builds TimeKeeperCore for unit tests / SwiftPM consumers.
//
import PackageDescription

let package = Package(
    name: "TimeKeeper",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "TimeKeeperCore", targets: ["TimeKeeperCore"])
    ],
    targets: [
        .target(
            name: "TimeKeeperCore",
            path: "Sources/TimeKeeperCore",
            resources: [
                // Seed JPGs live at package-root Resources/SeedPhotos.
                // SPM requires resources under the target, so we mirror them here
                // via Scripts/sync-seed-photos.sh (run once / on change).
                .copy("Resources/SeedPhotos")
            ]
        )
    ]
)
