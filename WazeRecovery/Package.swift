// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WazeRecovery",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WazeRecoveryCore",
            targets: ["WazeRecoveryCore", "WazeNativeEngine"]
        )
    ],
    targets: [
        .target(
            name: "WazeNativeEngine",
            path: "NativeEngine",
            exclude: [
                "Rendering/CanvasRenderer.metal",
                "Interop/NativeEngineBridge.mm"
            ],
            sources: [
                "Geometry/Coordinate.cpp",
                "Geometry/Polyline.cpp",
                "Routing/RoutingEngine.cpp",
                "Rendering/CanvasRenderer.cpp"
            ],
            publicHeadersPath: "."
        ),
        .target(
            name: "WazeRecoveryCore",
            dependencies: ["WazeNativeEngine"],
            path: "Sources",
            exclude: []
        ),
        .testTarget(
            name: "WazeRecoveryTests",
            dependencies: ["WazeRecoveryCore"],
            path: "Tests",
            exclude: [
                "GeometryTests.cpp",
                "RoutingEngineTests.cpp"
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
)
