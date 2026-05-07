// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ColorPicker",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "ColorPicker",
            dependencies: ["KeyboardShortcuts"],
            path: "Sources",
            resources: [.copy("presets.json"), .copy("AppIcon.png"), .copy("menu-icon.svg")]
        ),
    ]
)
