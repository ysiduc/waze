import SwiftUI

public struct BottomControlPanelView: View {
    @ObservedObject var sessionManager: NavigationSessionManager
    @Binding var isSearchSheetPresented: Bool
    
    public init(sessionManager: NavigationSessionManager, isSearchSheetPresented: Binding<Bool>) {
        self.sessionManager = sessionManager
        self._isSearchSheetPresented = isSearchSheetPresented
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            switch sessionManager.status {
            case .idle:
                Button(action: { isSearchSheetPresented = true }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Where to?")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)
                
            case .searching:
                HStack {
                    ProgressView()
                    Text("Calculating optimal routes...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
            case .previewingRoute:
                VStack(spacing: 12) {
                    if let selected = sessionManager.selectedRoute {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selected.name)
                                    .font(.headline)
                                HStack(spacing: 8) {
                                    Text(NavigationFormatters.formatDuration(selected.totalExpectedTimeSeconds))
                                        .font(.title2.bold())
                                        .foregroundColor(.green)
                                    Text("(\(NavigationFormatters.formatDistance(selected.totalDistanceMeters)))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            
                            Button(action: { sessionManager.startNavigation() }) {
                                Text("Go Now")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.accentColor)
                                    .cornerRadius(24)
                            }
                        }
                    }
                    
                    // Route options picker
                    if sessionManager.availableRoutes.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(sessionManager.availableRoutes) { route in
                                    Button(action: { sessionManager.selectRoute(route) }) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(route.name)
                                                .font(.caption)
                                            Text(NavigationFormatters.formatDuration(route.totalExpectedTimeSeconds))
                                                .font(.subheadline.bold())
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(route == sessionManager.selectedRoute ? Color.accentColor.opacity(0.15) : Color(uiColor: .tertiarySystemBackground))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(route == sessionManager.selectedRoute ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                        )
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    
                    Button(action: { sessionManager.stopNavigation() }) {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
            case .navigating, .rerouting:
                VStack(spacing: 8) {
                    if sessionManager.status == .rerouting {
                        HStack {
                            ProgressView()
                            Text("Rerouting...")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(NavigationFormatters.formatETA(sessionManager.metrics.estimatedArrivalTime))
                                    .font(.title.bold())
                                Text(NavigationFormatters.formatDuration(sessionManager.metrics.remainingTimeSeconds))
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            HStack(spacing: 12) {
                                Text(NavigationFormatters.formatDistance(sessionManager.metrics.remainingDistanceMeters))
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                Text(NavigationFormatters.formatSpeed(sessionManager.metrics.currentSpeedKph))
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        Spacer()
                        
                        Button(action: { sessionManager.stopNavigation() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                
            case .arrived:
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("You Have Arrived!")
                        .font(.title2.bold())
                    Button("Done") {
                        sessionManager.stopNavigation()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: -2)
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
