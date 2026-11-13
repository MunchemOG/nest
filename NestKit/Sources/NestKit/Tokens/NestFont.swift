/// A text style token from the `type` group of `design/tokens.json`. Sizes are in points.
public struct NestFont: Hashable, Sendable {
    /// The style's name in `tokens.json`, e.g. `display-xl`.
    public let name: String
    /// The family it is set in.
    public let family: Family
    /// Font size.
    public let size: Double
    /// Distance from one baseline to the next.
    public let lineHeight: Double
    /// CSS weight: 400 regular, 500 medium, 600 semibold.
    public let weight: Int
    /// Letter spacing as a fraction of the size (CSS `em`); negative tightens.
    public let letterSpacing: Double
    /// The specimen line `tokens.json` shows for this style.
    public let sample: String

    /// A style from its token values.
    public init(name: String, family: Family, size: Double, lineHeight: Double, weight: Int, letterSpacing: Double = 0, sample: String) {
        self.name = name
        self.family = family
        self.size = size
        self.lineHeight = lineHeight
        self.weight = weight
        self.letterSpacing = letterSpacing
        self.sample = sample
    }

    /// Letter spacing in points.
    public var tracking: Double { letterSpacing * size }

    /// The PostScript name of the face this style is set in, e.g. `InterTight-SemiBold`.
    public var postScriptName: String {
        let face = switch weight {
        case ..<450: "Regular"
        case ..<550: "Medium"
        default: "SemiBold"
        }
        return "\(family.postScriptPrefix)-\(face)"
    }

    /// The weight on Core Text's scale from -1 to 1, where regular is 0.
    public var coreTextWeight: Double {
        switch weight {
        case ..<450: 0
        case ..<550: 0.2
        default: 0.3
        }
    }

    /// A bird's name in its close-up. Once per view.
    public static let displayXL = NestFont(name: "display-xl", family: .display, size: 104, lineHeight: 96, weight: 600, letterSpacing: -0.045, sample: "Swift")
    /// The Home headline: one plain statement. Bird names take their own colour.
    public static let displayL = NestFont(name: "display-l", family: .display, size: 60, lineHeight: 61, weight: 500, letterSpacing: -0.038, sample: "Wren is holding focus until 15:30.")
    /// Big numbers: progress in a close-up.
    public static let displayM = NestFont(name: "display-m", family: .display, size: 64, lineHeight: 58, weight: 500, letterSpacing: -0.04, sample: "88%")
    /// Bird labels, widget titles and panel headings.
    public static let title = NestFont(name: "title", family: .display, size: 15, lineHeight: 20, weight: 500, letterSpacing: -0.01, sample: "Focus until 15:30")
    /// The line under the headline; a bird's status in its close-up.
    public static let bodyL = NestFont(name: "body-l", family: .sans, size: 19, lineHeight: 28, weight: 400, letterSpacing: -0.008, sample: "You’ve been in flow for 1 h 35 min.")
    /// The command bar, replies and default UI text.
    public static let body = NestFont(name: "body", family: .sans, size: 15, lineHeight: 22, weight: 400, letterSpacing: -0.005, sample: "Swift, build N1-15")
    /// Rows in the activity feed and needs-you cards.
    public static let bodyS = NestFont(name: "body-s", family: .sans, size: 13, lineHeight: 19, weight: 400, sample: "Switched to Focus mode until 15:30")
    /// Times, owners and metadata. Tabular numerals.
    public static let caption = NestFont(name: "caption", family: .sans, size: 12, lineHeight: 16, weight: 400, sample: "Wren · 13:30")
    /// Buttons, the mode switch, chips and tabs.
    public static let label = NestFont(name: "label", family: .sans, size: 13, lineHeight: 18, weight: 500, sample: "Build it")
    /// Code, commands and event topics only. Never as a label style.
    public static let code = NestFont(name: "code", family: .mono, size: 13, lineHeight: 21, weight: 400, sample: "swift.task.merged")

    /// Every text style, in the order `tokens.json` lists them.
    public static let styles: [NestFont] = [displayXL, displayL, displayM, title, bodyL, body, bodyS, caption, label, code]

    /// Every text style, by its name in `tokens.json`.
    public static let all: [String: NestFont] = Dictionary(uniqueKeysWithValues: styles.map { ($0.name, $0) })
}
