// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Ticker",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "Ticker", targets: ["Ticker"])],
    targets: [.executableTarget(name: "Ticker"), .testTarget(name: "TickerTests", dependencies: ["Ticker"])]
)
