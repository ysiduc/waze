import SwiftUI

public struct TopGuidanceBannerView: View {
    let step: GuidanceStep?
    let remainingDistanceMeters: Double
    
    public init(step: GuidanceStep?, remainingDistanceMeters: Double) {
        self.step = step
        self.remainingDistanceMeters = remainingDistanceMeters
    }
    
    public var body: some View {
        if let step = step {
            HStack(spacing: 16) {
                Image(systemName: step.maneuver.systemImageName)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(NavigationFormatters.formatDistance(step.distanceMeters))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(step.instruction)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
