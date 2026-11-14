import NestKit

/// What a `swift.report.ready` event says, read for its card: status, health, headline, each task's ending and the points.
struct ReportDetails: Equatable {
    let status: ReportStatus
    let health: String?
    let headline: String
    let tasks: [TaskEnding]
    let points: [ReportPoint]

    /// The details of Swift's report, or nil for any other event.
    init?(_ event: NestEvent) {
        guard event.topic == .swiftReportReady, let status = event.data["status"]?.string.flatMap(ReportStatus.init),
              let headline = event.data["headline"]?.string else { return nil }
        self.status = status
        self.headline = headline
        health = event.data["health"]?.string
        tasks = event.data["tasks"]?.strings?.compactMap(TaskEnding.init) ?? []
        guard case .array(let points)? = event.data["points"] else {
            self.points = []
            return
        }
        self.points = points.compactMap { point in
            if let text = point.string { return ReportPoint(figure: "", text: text) }
            guard case .object(let fields) = point, let text = fields["text"]?.string else { return nil }
            return ReportPoint(figure: fields["figure"]?.string ?? "", text: text)
        }
    }

    /// The status colour for a report.
    static func color(for status: ReportStatus) -> NestColor {
        switch status {
        case .green: .statusSuccess
        case .amber: .statusWarning
        case .red: .statusDanger
        }
    }

    /// The colour of one task's dot in the report's strip.
    static func color(for ending: TaskEnding) -> NestColor {
        switch ending {
        case .ok: .statusSuccess
        case .held: .statusWarning
        case .fail: .statusDanger
        }
    }
}
