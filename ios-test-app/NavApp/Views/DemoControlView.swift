import SwiftUI

public struct DemoControlView: View {
    @ObservedObject var sessionManager: NavigationSessionManager
    
    public init(sessionManager: NavigationSessionManager) {
        self.sessionManager = sessionManager
    }
    
    public var body: some View {
        HStack {
            Button(action: {
                sessionManager.toggleDemoMode()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: sessionManager.isDemoMode ? "play.circle.fill" : "play.circle")
                    Text(sessionManager.isDemoMode ? "DEMO MODE ACTIVE" : "ENABLE DEMO")
                        .font(.caption.bold())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(sessionManager.isDemoMode ? Color.orange : Color(uiColor: .systemGray5))
                .foregroundColor(sessionManager.isDemoMode ? .black : .primary)
                .cornerRadius(12)
            }
            
            if sessionManager.isDemoMode {
                Text("(Simulation along MKRoute)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}
