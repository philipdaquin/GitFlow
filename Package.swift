// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "GitFlow", version: "1.0.0", description: "A modern CLI for Git workflows", license: .mit, authors: [.init(name: "Philip Daquin", email: "philip@daquin.com")], targets: [.executableTarget(name: "GitFlow", dependencies: [], path: "Sources/GitFlow")])
