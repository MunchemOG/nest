extension NestFont {
    /// A font family from the `type.families` group of `design/tokens.json`.
    public enum Family: String, CaseIterable, Hashable, Sendable {
        /// Inter Tight: display lines and titles.
        case display
        /// Inter: running text and labels.
        case sans
        /// IBM Plex Mono: code, commands and event topics only.
        case mono

        /// The family's name as the system knows it.
        public var name: String {
            switch self {
            case .display: "Inter Tight"
            case .sans: "Inter"
            case .mono: "IBM Plex Mono"
            }
        }

        /// The prefix of each face's PostScript name, e.g. `InterTight` in `InterTight-Medium`.
        var postScriptPrefix: String {
            switch self {
            case .display: "InterTight"
            case .sans: "Inter"
            case .mono: "IBMPlexMono"
            }
        }
    }
}
