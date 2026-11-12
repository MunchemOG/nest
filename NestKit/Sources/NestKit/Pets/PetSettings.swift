import Foundation

/// Every pet-mode threshold, in seconds unless noted, with the spec's defaults.
public struct PetSettings: Hashable, Sendable, Codable {
    /// How long between visits.
    public var visitGap: ClosedRange<TimeInterval> = 600...1200
    /// How long a visit lasts.
    public var visitLength: ClosedRange<TimeInterval> = 60...240
    /// Continuous input before a break buddy comes out.
    public var breakAfter: TimeInterval = 3000
    /// A pause in input at least this long ends a work streak.
    public var breakPause: TimeInterval = 300
    /// How long a break buddy stays.
    public var breakLength: TimeInterval = 180
    /// How many birds come out for a break.
    public var breakBirds: ClosedRange<Int> = 2...3
    /// How long after a break ends before another can start.
    public var breakCooldown: TimeInterval = 1200
    /// Bundle ids of meeting apps that hide the pets.
    public var meetingApps: Set<String> = ["us.zoom.xos", "com.microsoft.teams2", "com.apple.FaceTime"]
    /// Time without input before every idle bird comes out.
    public var livelyAfter: TimeInterval = 180
    /// How long birds take to drift home when input returns after lively.
    public var livelySettle: TimeInterval = 2
    /// How long a flight between perches takes.
    public var flightTime: TimeInterval = 1.5
    /// The local hour Owl's night rule starts.
    public var nightStartHour = 23
    /// The local hour Owl's night rule ends.
    public var nightEndHour = 5
    /// The least distance between two perched birds, in points.
    public var perchSpacing: Double = 32
    /// How close the pointer must be to count as hovering a bird, in points.
    public var hoverRadius: Double = 28
    /// Below this pointer speed the pointer counts as still, in points a second.
    public var stillSpeed: Double = 60
    /// How close the pointer must be for a bird to approach, follow or watch it, in points.
    public var approachRadius: Double = 220
    /// How long the pointer must be still before a bird approaches.
    public var approachAfter: TimeInterval = 2
    /// How long the pointer must be still before a brave bird sits on it.
    public var sitAfter: TimeInterval = 4
    /// How far behind the pointer a following bird keeps, in points.
    public var followDistance: Double = 120

    /// Settings with every default.
    public init() {}

    /// How long every bird takes to get home when hidden or busy: the `duration-slow` token.
    public static var goHome: TimeInterval {
        let parts = NestMotion.slow.components
        return Double(parts.seconds) + Double(parts.attoseconds) / 1e18
    }
}
