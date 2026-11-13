import NestKit

/// Where a panel sits.
enum NestPanelKind: String, CaseIterable, Hashable, Sendable {
    /// Part of the layout over the scene: the rail, widgets, the activity feed. Smoked glass.
    case solid
    /// Opened over everything else, closed by Escape or a click outside: menus, sheets, popovers.
    case floating

    /// The panel's fill.
    var fill: NestColor {
        switch self {
        case .solid: .glass
        case .floating: .surface3
        }
    }

    /// The panel's shadow.
    var shadow: NestShadow {
        switch self {
        case .solid: .panel
        case .floating: .popover
        }
    }

    /// Whether what is behind the panel is blurred (`blur-glass`).
    var usesBackdropBlur: Bool { self == .solid }
}
