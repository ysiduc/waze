import Foundation

public struct NavigationFormatters {
    public static func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.1f km", meters / 1000.0)
        }
    }
    
    public static func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(round(seconds / 60.0))
        if mins < 60 {
            return "\(mins) min"
        } else {
            let hours = mins / 60
            let remMins = mins % 60
            return "\(hours) hr \(remMins) min"
        }
    }
    
    public static func formatETA(_ date: Date) -> String {
        let df = DateFormatter()
        df.timeStyle = .short
        return df.string(from: date)
    }
    
    public static func formatSpeed(_ kph: Double) -> String {
        return String(format: "%.0f km/h", kph)
    }
}
