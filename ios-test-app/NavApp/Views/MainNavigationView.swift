import SwiftUI

public struct MainNavigationView: View {
    @StateObject private var sessionManager = NavigationSessionManager()
    @State private var isSearchSheetPresented: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Map layer
            MapViewContainer(sessionManager: sessionManager)
                .ignoresSafeArea()
            
            // Overlay controls
            VStack(spacing: 8) {
                // Top guidance banner (shown during active navigation)
                if sessionManager.status == .navigating || sessionManager.status == .rerouting {
                    TopGuidanceBannerView(
                        step: sessionManager.currentStep,
                        remainingDistanceMeters: sessionManager.metrics.remainingDistanceMeters
                    )
                }
                
                // Demo control button
                DemoControlView(sessionManager: sessionManager)
                
                Spacer()
                
                // Bottom control panel (Search / Route preview / Active metrics)
                BottomControlPanelView(
                    sessionManager: sessionManager,
                    isSearchSheetPresented: $isSearchSheetPresented
                )
            }
        }
        .onAppear {
            sessionManager.locationService.requestAuthorization()
        }
        .sheet(isPresented: $isSearchSheetPresented) {
            SearchSheetView(searchService: sessionManager.searchService) { destination in
                sessionManager.selectDestination(destination)
            }
        }
    }
}
