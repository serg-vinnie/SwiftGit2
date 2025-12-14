// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "SwiftGit2",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftGit2",
            targets: ["SwiftGit2"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", exact: "1.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-parsing.git", exact: "0.10.0"),
        .package(url: "https://gitlab.com/sergiy.vynnychenko/essentials.git", branch: "master"),
        .package(url: "https://github.com/Quick/Nimble.git", exact: "8.1.2"),
        .package(url: "https://github.com/Quick/Quick.git", exact: "2.2.1"),
    ],
    targets: [
        .binaryTarget(
            name: "Clibgit2",
            path: "Sources/Clibgit2/Clibgit2.xcframework"
        ),
        
        .target(
            name: "Git2Init",
            dependencies: ["Clibgit2"],
            path: "Sources/Cibgit2Init"
        ),
        
        .target(
            name: "SwiftGit2",
            dependencies: [
                "Clibgit2",
                "Git2Init",
                .product(name: "Collections", package: "swift-collections"),
                
                // To run tests need to swith name to "EssentialsStatic"
                .product(name: "Essentials", package: "Essentials"),
                .product(name: "Parsing", package: "swift-parsing"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("iconv")
            ]
        ),
        
        .testTarget(
            name: "SwiftGit2Tests",
            dependencies: [
                "SwiftGit2",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble"),
                .product(name: "EssentialsTesting", package: "Essentials"),
            ]
        )
    ]
)
