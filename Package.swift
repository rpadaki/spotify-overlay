// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpotifyOverlay",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SpotifyOverlay",
            targets: ["SpotifyOverlay"])
    ],
    targets: [
        .executableTarget(
            name: "SpotifyOverlay",
            path: ".",
            exclude: ["README.md"]
        )
    ]
)
