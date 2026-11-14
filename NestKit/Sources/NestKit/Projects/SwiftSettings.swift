/// Everything you set for Swift: your limits and the projects it works on, in the order it visits them.
public struct SwiftSettings: Sendable, Equatable, Codable {
    /// How much of your plan Swift may use.
    public var limits: SwiftLimits
    /// The projects Swift works on.
    public var projects: [SwiftProject]

    /// Settings with these limits and projects.
    public init(limits: SwiftLimits, projects: [SwiftProject]) {
        self.limits = limits
        self.projects = projects
    }
}
