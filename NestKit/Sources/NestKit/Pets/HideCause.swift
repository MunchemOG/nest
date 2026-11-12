/// A reason every pet must stay home.
public enum HideCause: Hashable, Sendable, CaseIterable {
    /// The pets hotkey turned pets off.
    case hotkeyOff
    /// A full-screen app is in front.
    case fullScreen
    /// A known meeting app is in front.
    case meetingApp
    /// Reduce Motion is on.
    case reduceMotion
}
