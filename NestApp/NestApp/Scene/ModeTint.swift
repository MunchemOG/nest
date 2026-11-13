import NestKit

/// The colour of the studio's wall light for a mode name from `wren.mode.changed`.
enum ModeTint {
    static func colour(for mode: String?) -> NestColor {
        switch mode {
        case "Morning": .modeMorning
        case "Focus": .modeFocus
        default: .modeNight
        }
    }
}
