// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "LaserMouse",
  platforms: [.macOS(.v14)],
  targets: [
    .target(name: "LaserMouseCore"),
    .executableTarget(name: "LaserMouse", dependencies: ["LaserMouseCore"]),
    .testTarget(name: "LaserMouseCoreTests", dependencies: ["LaserMouseCore"]),
  ]
)
