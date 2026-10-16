import Foundation

/// Navigation Maneuver instructions matching Waze guidance icons and banners.
public enum WZManeuverType: String, Codable {
    case depart = "depart"
    case `continue` = "continue"
    case turnLeft = "turn_left"
    case turnRight = "turn_right"
    case sharpLeft = "sharp_left"
    case sharpRight = "sharp_right"
    case slightLeft = "slight_left"
    case slightRight = "slight_right"
    case uTurn = "u_turn"
    case merge = "merge"
    case roundabout = "roundabout"
    case arrive = "arrive"

    public var iconSymbolName: String {
        switch self {
        case .depart: return "arrow.up.circle.fill"
        case .continue: return "arrow.up"
        case .turnLeft: return "arrow.turn.up.left"
        case .turnRight: return "arrow.turn.up.right"
        case .sharpLeft: return "arrow.turn.left.up"
        case .sharpRight: return "arrow.turn.right.up"
        case .slightLeft: return "arrow.up.left"
        case .slightRight: return "arrow.up.right"
        case .uTurn: return "arrow.uturn.down"
        case .merge: return "arrow.triangle.merge"
        case .roundabout: return "arrow.triangle.turn.up.right.circle"
        case .arrive: return "mappin.circle.fill"
        }
    }
}
