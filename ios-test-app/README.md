# Independent iOS Navigation Test Application (NavApp)

**Target Platform:** iOS 16.0+ (SwiftUI, MapKit, CoreLocation)  
**Bundle Identifier:** `com.ysiduc.navapp`  
**Purpose:** Clean-room independent functional navigation prototype built to evaluate reconstruction feasibility based on Phase 1 static analysis research.

---

## Clean-Room Architectural Boundaries

> [!IMPORTANT]
> This application is an **independent, clean-room implementation** developed solely with public Apple APIs (`MapKit`, `CoreLocation`, `Combine`, `SwiftUI`).
> - It contains **no decompiled proprietary code**, **no private APIs**, and **no intellectual property or assets** from Waze Mobile Ltd. or Google LLC.
> - Map data, geocoding, and routing services are provided exclusively by Apple Maps (`MKLocalSearch`, `MKDirections`) under Apple's Developer Terms of Service.
> - It does not connect to or communicate with proprietary Waze routing, reporting, or social servers.

---

## Subsystem Architecture

```
ios-test-app/
├── NavApp/
│   ├── App/
│   │   ├── NavApp.swift                # SwiftUI Application lifecycle
│   │   └── Info.plist                  # CoreLocation & Background audio/location keys
│   ├── Models/
│   │   ├── NavigationState.swift       # State machine status (idle, search, preview, nav)
│   │   ├── ManeuverType.swift          # Typed turn icons & instructions
│   │   ├── GuidanceStep.swift          # Turn-by-turn guidance step record
│   │   ├── RouteModel.swift            # Encapsulates MKRoute, distance, travel time
│   │   ├── LocationModel.swift         # Filtered coordinate, course, and speed
│   │   └── SearchResult.swift          # Destination placemark record
│   ├── Services/
│   │   ├── Formatters.swift            # Distance, duration, speed, and ETA formatters
│   │   ├── LocationService.swift       # CLLocationManager delegate & filter
│   │   ├── RoutingService.swift        # MKDirections multi-route engine
│   │   ├── SearchService.swift         # MKLocalSearch geocoding & autocomplete
│   │   └── NavigationSessionManager.swift # State coordinator & simulation engine
│   └── Views/
│       ├── MainNavigationView.swift    # Root container
│       ├── MapViewContainer.swift      # MKMapView UIViewRepresentable with route overlays
│       ├── TopGuidanceBannerView.swift # Floating turn instruction card
│       ├── BottomControlPanelView.swift# ETA, remaining distance, search trigger
│       ├── SearchSheetView.swift       # Destination search interface
│       └── DemoControlView.swift       # Clearly marked [DEMO MODE] simulator toggle
└── NavAppTests/                        # XCTest unit testing suite
```

---

## Building and Running

### Prerequisites
- macOS Sonoma or Sequoia with **Xcode 15.0+**
- Apple Developer Account (optional for Simulator; required for signed device installation)

### 1. Build for iOS Simulator
```bash
xcodebuild build \
    -project NavApp.xcodeproj \
    -scheme NavApp \
    -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO
```

### 2. Execute Automated Unit Tests
```bash
xcodebuild test \
    -project NavApp.xcodeproj \
    -scheme NavApp \
    -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO
```

### 3. Build Device Archive (Unsigned)
```bash
xcodebuild archive \
    -project NavApp.xcodeproj \
    -scheme NavApp \
    -archivePath build/NavApp.xcarchive \
    -destination "generic/platform=iOS" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO
```

---

## Operating Modes

1. **Live GPS Navigation:**
   Requires a physical iPhone with GPS reception. Calculates routes using Apple's navigation routing service, tracks physical speed via `CLLocation.speed`, and updates distance and next-turn maneuvers dynamically.

2. **Demo Mode (`[DEMO MODE]`):**
   Designed specifically for automated testing and the iOS Simulator without requiring physical road testing. When enabled via the on-screen button, the app animates progress along the calculated `MKRoute`, advancing through turn maneuvers and updating simulated speed and ETA in real time.
