// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "KeyboardPanelKit",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "KeyboardPanelKit",
            targets: ["KeyboardPanelKit"]),
    ],
    targets: [
        .target(
            name: "KeyboardPanelKit",
            dependencies: [],
            exclude: [
                "context_ai.md",
                "Keyboard/context_ai.md",
                "Core/context_ai.md",
                "Panel/context_ai.md",
                "Bridge/context_ai.md",
                "Demo/context_ai.md"
            ]
        ),
    ]
)
