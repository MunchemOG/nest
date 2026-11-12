/// A small flourish a pet does on top of its activity.
public enum PetReaction: Hashable, Sendable {
    /// Hops toward the pointer.
    case hopCloser
    /// Sits on a still pointer.
    case sitOnPointer
    /// Tilts its head at what's hovered.
    case tiltHead
    /// Turns its head to watch the pointer.
    case watch
    /// Blinks.
    case blink
    /// Steals a sparkle from the pointer.
    case stealSparkle
    /// Fans its tail.
    case fanTail
    /// Huffs off.
    case huff
    /// Darts away.
    case dartAway
    /// Carries a glint back to the nest.
    case carryGlint
}
