// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InternetSpeed",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "InternetSpeed",
            path: "Sources/InternetSpeed",
            exclude: ["Info.plist", "AppIcon.icns", "Assets.xcassets"]
        ),
    ]
)
