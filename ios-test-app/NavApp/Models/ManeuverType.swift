import Foundation

public enum ManeuverType: String, Equatable, CaseIterable {
    case straight
    case slightLeft
    case slightRight
    case turnLeft
    case turnRight
    case sharpLeft
    case sharpRight
    case uTurn
    case enterRoundabout
    case exitRoundabout
    case arrive
    case unknown
    
    public var systemImageName: String {
        switch self {
        case .straight: return "arrow.up"
        case .slightLeft: return "arrow.up.left"
        case .slightRight: return "arrow.up.right"
        case .turnLeft: return "arrow.turn.up.left"
        case .turnRight: return "arrow.turn.up.right"
        case .sharpLeft: return "arrow.uturn.left"
        case .sharpRight: return "arrow.uturn.right"
        case .uTurn: return "arrow.uturn.down"
        case .enterRoundabout, .exitRoundabout: return "arrow.triangle.2.circlepath"
        case .arrive: return "mappin.and.ellipse"
        case .unknown: return "arrow.up"
        }
    }
    
    public static func fromInstruction(_ instruction: String) -> ManeuverType {
        let lower = instruction.lowercased()
        if lower.contains("arrive") || lower.contains("destination") { return .arrive }
        if lower.contains("u-turn") || lower.contains("make a u-turn") { return .uTurn }
        if lower.contains("roundabout") { return .enterRoundabout }
        if lower.contains("sharp left") { return .sharpLeft }
        if lower.contains("sharp right") { return .sharpRight }
        if lower.contains("slight left") || lower.contains("bear left") { return .slightLeft }
        if lower.contains("slight right") || lower.contains("bear right") { return .slightRight }
        if lower.contains("left") { return .turnLeft }
        if lower.contains("right") { return .turnRight }
        if lower.contains("straight") || lower.contains("continue") || lower.contains("head") { return .straight }
        return .straight
    }
}
