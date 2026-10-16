# Automated Test Suite: NavApp

This directory indexes and documents the automated test suite for the independent iOS navigation application (`ios-test-app/NavAppTests/`).

## Test Target Overview
- **Framework:** Apple `XCTest`
- **Execution Target:** iOS Simulator (`platform=iOS Simulator,name=iPhone 15,OS=latest`)
- **Source Location:** `ios-test-app/NavAppTests/`

## Test Modules & Assertions

1. **`NavigationStateTests.swift`**
   - `testInitialStatusIsIdle`: Verifies initialization defaults, empty active route, nil destination, and status `.idle`.
   - `testStartAndStopNavigation`: Validates state transition lifecycle from `.previewingRoute` to `.navigating` and teardown back to `.idle`.

2. **`FormattingTests.swift`**
   - `testDistanceFormattingMeters`: Verifies sub-kilometer distance formatting (`350 m`, `999 m`).
   - `testDistanceFormattingKilometers`: Verifies kilometer formatting with 1-decimal precision (`1.0 km`, `15.4 km`).
   - `testDurationFormattingMinutes`: Verifies minute rounding (`3 min`, `20 min`).
   - `testDurationFormattingHoursAndMinutes`: Verifies compound time strings (`1 hr 1 min`, `2 hr 0 min`).
   - `testSpeedFormatting`: Verifies integer velocity presentation (`0 km/h`, `65 km/h`).

3. **`RouteModelTests.swift`**
   - `testManeuverTypeDetection`: Validates natural-language turn parsing to typed maneuver enums (left, right, sharp turn, u-turn, roundabout, arrival, straight).
   - `testRouteModelInitialization`: Verifies step geometry, distance totals, expected duration, and polyline coordinate counts.

4. **`LocationModelTests.swift`**
   - `testSpeedConversion`: Validates exact meters/second to km/h and mph conversions.
   - `testInvalidAccuracy`: Rejects negative or poor horizontal accuracy (> 100 meters).

5. **`NavigationSessionManagerTests.swift`**
   - `testRouteSelectionUpdatesMetrics`: Asserts selected route duration and distance propagate to published metrics.
   - `testLocationUpdateAdvancesStep`: Tests real-time coordinate proximity triggering automatic step advancement to next guidance maneuver.
   - `testDemoModeToggle`: Tests interactive simulation state management.

## CI Execution Command
```bash
xcodebuild test \
    -project ios-test-app/NavApp.xcodeproj \
    -scheme NavApp \
    -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO
```
