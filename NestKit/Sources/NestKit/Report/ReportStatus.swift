/// How a run went, in one word (see `docs/minds/swift.md`).
public enum ReportStatus: String, Sendable, Equatable {
    /// Everything merged, or what was held was held on purpose, and the Nest is healthy.
    case green
    /// A failure Swift cannot explain, or usage close to the reserve.
    case amber
    /// The Nest is broken and Swift could not roll it back. The only status that pings.
    case red
}
