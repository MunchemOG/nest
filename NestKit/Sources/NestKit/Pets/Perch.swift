/// A place a pet can land.
public struct Perch: Hashable, Sendable {
    /// What the perch is; a lower raw value is preferred.
    public enum Kind: Int, CaseIterable, Comparable, Hashable, Sendable {
        /// A Dock icon, found through Accessibility.
        case dockIcon
        /// The Dock's top edge.
        case dockEdge
        /// The top edge of a visible window.
        case windowTop
        /// The menu bar.
        case menuBar

        /// Orders kinds by preference, most preferred first.
        public static func < (lhs: Kind, rhs: Kind) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// What the perch is.
    public var kind: Kind
    /// Where a bird sits on it.
    public var point: PetPoint
    /// The bundle id of the app the perch belongs to, if any.
    public var app: String?

    /// A perch of `kind` at `point`, belonging to `app`.
    public init(kind: Kind, point: PetPoint, app: String? = nil) {
        self.kind = kind
        self.point = point
        self.app = app
    }
}
