/// The screens the rail leads to, in the approved order.
enum NestScreen: String, CaseIterable, Hashable, Sendable {
    case home
    case activity
    case memory
    case settings

    /// The name shown as the button's label and the screen's heading.
    var title: String {
        switch self {
        case .home: "Home"
        case .activity: "Activity"
        case .memory: "Memory"
        case .settings: "Settings"
        }
    }

    /// The SF Symbol on the rail button.
    var symbol: String {
        switch self {
        case .home: "house"
        case .activity: "waveform.path.ecg"
        case .memory: "book.closed"
        case .settings: "slider.horizontal.3"
        }
    }

    /// The digit that, with Command, opens the screen.
    var shortcut: Character {
        switch self {
        case .home: "1"
        case .activity: "2"
        case .memory: "3"
        case .settings: "4"
        }
    }

    /// Whether the button sits below the rail's divider.
    var isBelowDivider: Bool { self == .settings }

    /// The rail button's accessibility identifier.
    var railID: String { "rail.\(rawValue)" }

    /// The screen's accessibility identifier.
    var screenID: String { "screen.\(rawValue)" }
}
