// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "HubChat",
    platforms: [.iOS(.v13)],
    products: [.library(name: "HubChat", targets: ["HubChat"])],
    targets: [.target(name: "HubChat", path: "Sources/HubChat")]
)
