# Waze iOS Architecture & Subsystem Relationship Diagrams

This document contains Mermaid diagrams illustrating the architectural relationships, data flows, and subsystem boundaries discovered during static reverse engineering of Waze iOS v5.22.0.

> **Audit & Verification Legend:**
> - Solid lines (`──>`) represent **VERIFIED** relationships confirmed through direct code references, method calls, or class metadata.
> - Dashed lines (`-.->`) represent **INFERRED** relationships based on architectural conventions, error strings, and protocol structures.
> - All sequence diagrams represent inferred operational flows reconstructed from client parsing routines rather than live network packet captures.

---

## 1. Top-Level Subsystem Architecture

```mermaid
graph TD
    classDef verified fill:#2b6cb0,stroke:#2d3748,stroke-width:2px,color:#fff;
    classDef inferred fill:#718096,stroke:#2d3748,stroke-width:1px,stroke-dasharray: 5 5,color:#fff;
    classDef external fill:#4a5568,stroke:#2d3748,stroke-width:1px,color:#fff;

    subgraph UI_Layer ["Front-End Layer (Swift / SwiftUI / UIKit) [VERIFIED CLASSES]"]
        UI_Root["Root View Controller"]:::verified
        UI_CarPlay["WZCarPlayMapController (0x107f17e30)"]:::verified
        UI_SwiftNav["WazeNavigationGuidance Module"]:::verified
    end

    subgraph Bridge_Layer ["Bridging & Reducer Layer (Objective-C++) [VERIFIED METHODS]"]
        B_Canvas["MainCanvasViewHolder (0x107f1a4a0)"]:::verified
        B_NavReducer["NavigationGuidanceReducerBridge (0x107f1ab08)"]:::verified
        B_AltRoutes["AlternateRoutesStateMachineBridge (0x107f17048)"]:::verified
        B_Location["WZWazeLocationServiceBridge (0x107f19690)"]:::verified
    end

    subgraph Core_Layer ["Core Logic & Engine Layer (C++) [INFERRED CORE]"]
        C_MetalRender["Metal Rendering Pipeline"]:::inferred
        C_RoutingCore["Routing State & Maneuver Engine"]:::inferred
        C_SpatialIndex["Spatial Tiling Engine"]:::inferred
    end

    subgraph Hardware_Layer ["iOS Frameworks & Hardware Services [VERIFIED LOAD COMMANDS]"]
        HW_Metal["Apple Metal Framework & default.metallib (67,042 B)"]:::external
        HW_GPS["CoreLocation Telemetry"]:::external
        HW_BT["CoreBluetooth (Tunnel Beacon Usage String)"]:::external
        HW_Net["gRPC Transport (roots.pem)"]:::external
    end

    UI_Root -.-> B_Canvas
    UI_CarPlay -.-> B_Canvas
    UI_SwiftNav -.-> B_NavReducer

    B_Canvas -.-> C_MetalRender
    B_NavReducer -.-> C_RoutingCore
    B_AltRoutes -.-> C_RoutingCore
    B_Location --> HW_GPS
    B_Location -.-> HW_BT

    C_MetalRender -.-> HW_Metal
    C_SpatialIndex -.-> HW_Metal
    C_RoutingCore -.-> HW_Net

    linkStyle 0,1,2,3,4,5,7,8,9,10 stroke:#718096,stroke-width:2px,stroke-dasharray: 5 5;
    linkStyle 6 stroke:#2b6cb0,stroke-width:2px;
```

---

## 2. Map Canvas Rendering Pipeline

```mermaid
flowchart TD
    classDef verified fill:#2b6cb0,stroke:#2d3748,stroke-width:2px,color:#fff;
    classDef inferred fill:#718096,stroke:#2d3748,stroke-width:1px,stroke-dasharray: 5 5,color:#fff;

    A["MainCanvasViewHolder.mm (0x107f1a4a0)"]:::verified -->|Selector: createMetalViewController| B["MetalViewController (Inferred Binding)"]:::inferred
    B -.->|Binds viewport & canvas size| C["CarPlayCanvasViewPortUtilities"]:::verified
    B -.->|Loads compiled GPU shaders| D["default.metallib (67,042 B)"]:::verified

    subgraph Shader_Pipelines ["Metal Shaders (default.metallib) [VERIFIED IN BYTECODE]"]
        D --> S1["BlurVertexShader / BlurFragmentShader"]:::verified
        D --> S2["SimpleTextureVertexShader / SimpleTextureFragmentShader"]:::verified
    end

    subgraph Vector_Tiling ["Vector Geometry & Styling [VERIFIED STRINGS]"]
        E["TileLineStyle Layout Buffer"]:::verified
        E -.->|Inferred uniform binding| F["Rasterizer Pipeline"]:::inferred
    end

    S2 -.-> F
    F -.-> G["GPU Display Surface (CAMetalLayer)"]:::inferred

    linkStyle 0 stroke:#2b6cb0,stroke-width:2px;
    linkStyle 1,2 stroke:#718096,stroke-width:2px,stroke-dasharray: 5 5;
    linkStyle 3,4 stroke:#2b6cb0,stroke-width:2px;
    linkStyle 5,6,7 stroke:#718096,stroke-width:2px,stroke-dasharray: 5 5;
```

---

## 3. Route Guidance & Reroute Event Pipeline (Inferred Data Flow)

> *Note: This sequence illustrates the inferred control and data flow derived from parsing routines and error assertions in `AlternateRoutesStateMachineBridge::ParseToRoutingUpdateResponse` (`0x10001a718`). Live network messages were not dynamically captured.*

```mermaid
sequenceDiagram
    autonumber
    participant Server as Waze Backend Server (gRPC) [Inferred]
    participant AltBridge as AlternateRoutesStateMachineBridge [Verified]
    participant CoreNav as Navigation Guidance Core [Inferred]
    participant Reducer as NavigationGuidanceReducerBridge [Verified]
    participant SwiftUI as Swift Guidance UI [Verified]

    Server-->>AltBridge: Push RoutingUpdateResponse (Protobuf Payload)
    Note over AltBridge: 0x10001a718 parses CurrentRouteUpdate,<br/>RerouteSuggestion, NextUpdateSchedule
    AltBridge-->>CoreNav: Trigger State Machine Update (Inferred)
    CoreNav-->>Reducer: Dispatch Guidance Event (Approach Turn / Reroute)
    Note over Reducer: Swift properties distanceToTurn,<br/>isApproachingTurn updated
    Reducer-->>SwiftUI: Emit Navigation State Snapshot (Inferred)
    Note over SwiftUI: Updates Turn Banner & HUD Display
```

---

## 4. Location Telemetry & Speed Bridging

```mermaid
flowchart LR
    classDef verified fill:#2b6cb0,stroke:#2d3748,stroke-width:2px,color:#fff;
    classDef inferred fill:#718096,stroke:#2d3748,stroke-width:1px,stroke-dasharray: 5 5,color:#fff;

    GPS["iOS CoreLocation Service"]:::verified -->|CLLocation callback| Bridge["WZWazeLocationServiceBridge (0x107f19690)"]:::verified
    BT["Bluetooth Peripheral Beacon"]:::verified -.->|Inferred Tunnel RSSI Proximity| Bridge

    Bridge -->|0x1000a1d28: Passes lat/lon doubles| Model["WSVLocationSpeed Model"]:::verified
    Model -.->|Inferred Telemetry stream| UI["Speedometer & Navigation State"]:::inferred

    linkStyle 0,2 stroke:#2b6cb0,stroke-width:2px;
    linkStyle 1,3 stroke:#718096,stroke-width:2px,stroke-dasharray: 5 5;
```
