// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Package",
  defaultLocalization: "ja",
  platforms: [.iOS(.v17), .macOS(.v12)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "AppFeature",
      targets: [
        "AppFeature"
      ]
    ),
    .library(
      name: "AppTabFeature",
      targets: [
        "AppTabFeature"
      ]
    ),
    .library(
      name: "DocumentFeature",
      targets: [
        "DocumentFeature"
      ]
    ),
    .library(
      name: "CharcoalTimerFeature",
      targets: [
        "CharcoalTimerFeature"
      ]
    ),
    .library(
      name: "SettingFeature",
      targets: [
        "SettingFeature"
      ]
    ),
    .library(
      name: "Extension",
      targets: [
        "Extension"
      ]
    ),
    .library(
      name: "Domain",
      targets: [
        "Domain"
      ]
    ),
    .library(
      name: "Common",
      targets: [
        "Common"
      ]
    )
  ],
  dependencies: [
    // 外部パッケージの依存関係の追加
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture.git",
      exact: "1.21.1"
    ),
    .package(url: "https://github.com/aws-amplify/amplify-swift", exact: "2.50.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "AppFeature",
      dependencies: [
        "AppTabFeature",
        "Extension",
        "Domain",
        "Common",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "Amplify", package: "amplify-swift"),
        .product(name: "AWSAPIPlugin", package: "amplify-swift")
      ]
    ),
    .target(
      name: "AppTabFeature",
      dependencies: [
        "DocumentFeature",
        "CharcoalTimerFeature",
        "Extension",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "DocumentFeature",
      dependencies: [
        "Extension",
        "Domain",
        "Common",
        "SettingFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "CharcoalTimerFeature",
      dependencies: [
        "Extension",
        "Domain",
        "Common",
        "SettingFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "SettingFeature",
      dependencies: [
        "Extension",
        "Domain",
        "Common",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "Extension"
    ),
    .target(
      name: "Domain",
      dependencies: [
        "Extension",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "Amplify", package: "amplify-swift"),
        .product(name: "AWSAPIPlugin", package: "amplify-swift")
      ]
    ),
    .target(
      name: "Common",
      dependencies: [
        "Domain",
        "Extension",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ],
      resources: [
        .process("Resources")
      ]
    ),
    .testTarget(
      name: "Tests",
      dependencies: [
        "Domain",
        "Extension",
        "SettingFeature",
        "DocumentFeature",
        "CharcoalTimerFeature",
        "AppTabFeature",
        "AppFeature",
        "Common",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ],
      path: "Tests"
    )
  ]
)
