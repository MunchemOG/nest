/// An event's topic, `<bird>.<thing>.<what happened>`. Topics the contract doesn't list are kept as written.
public struct EventTopic: RawRepresentable, Hashable, Sendable, Decodable {
    /// The topic as written.
    public let rawValue: String

    /// A topic from its text.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Whether `docs/event-bus.md` lists this topic.
    public var isKnown: Bool {
        Self.known.contains(self)
    }

    /// `owl.presence.changed`.
    public static let owlPresenceChanged = EventTopic(rawValue: "owl.presence.changed")

    /// `owl.flow.changed`.
    public static let owlFlowChanged = EventTopic(rawValue: "owl.flow.changed")

    /// `owl.distraction.noticed`.
    public static let owlDistractionNoticed = EventTopic(rawValue: "owl.distraction.noticed")

    /// `owl.nudge.given`.
    public static let owlNudgeGiven = EventTopic(rawValue: "owl.nudge.given")

    /// `owl.screen.locked`.
    public static let owlScreenLocked = EventTopic(rawValue: "owl.screen.locked")

    /// `owl.gesture.done`.
    public static let owlGestureDone = EventTopic(rawValue: "owl.gesture.done")

    /// `wren.file.moved`.
    public static let wrenFileMoved = EventTopic(rawValue: "wren.file.moved")

    /// `wren.file.renamed`.
    public static let wrenFileRenamed = EventTopic(rawValue: "wren.file.renamed")

    /// `wren.file.skipped`.
    public static let wrenFileSkipped = EventTopic(rawValue: "wren.file.skipped")

    /// `wren.folder.created`.
    public static let wrenFolderCreated = EventTopic(rawValue: "wren.folder.created")

    /// `wren.look.changed`.
    public static let wrenLookChanged = EventTopic(rawValue: "wren.look.changed")

    /// `wren.mode.changed`.
    public static let wrenModeChanged = EventTopic(rawValue: "wren.mode.changed")

    /// `wren.workspace.restored`.
    public static let wrenWorkspaceRestored = EventTopic(rawValue: "wren.workspace.restored")

    /// `swift.run.started`.
    public static let swiftRunStarted = EventTopic(rawValue: "swift.run.started")

    /// `swift.run.finished`.
    public static let swiftRunFinished = EventTopic(rawValue: "swift.run.finished")

    /// `swift.task.merged`.
    public static let swiftTaskMerged = EventTopic(rawValue: "swift.task.merged")

    /// `swift.task.held`.
    public static let swiftTaskHeld = EventTopic(rawValue: "swift.task.held")

    /// `swift.task.failed`.
    public static let swiftTaskFailed = EventTopic(rawValue: "swift.task.failed")

    /// `swift.merge.rolled_back`.
    public static let swiftMergeRolledBack = EventTopic(rawValue: "swift.merge.rolled_back")

    /// `swift.report.ready`.
    public static let swiftReportReady = EventTopic(rawValue: "swift.report.ready")

    /// `crow.friction.seen`.
    public static let crowFrictionSeen = EventTopic(rawValue: "crow.friction.seen")

    /// `crow.pitch.made`.
    public static let crowPitchMade = EventTopic(rawValue: "crow.pitch.made")

    /// `crow.pitch.answered`.
    public static let crowPitchAnswered = EventTopic(rawValue: "crow.pitch.answered")

    /// `magpie.note.written`.
    public static let magpieNoteWritten = EventTopic(rawValue: "magpie.note.written")

    /// `magpie.note.linked`.
    public static let magpieNoteLinked = EventTopic(rawValue: "magpie.note.linked")

    /// `magpie.lesson.learned`.
    public static let magpieLessonLearned = EventTopic(rawValue: "magpie.lesson.learned")

    /// `magpie.memory.forgotten`.
    public static let magpieMemoryForgotten = EventTopic(rawValue: "magpie.memory.forgotten")

    /// `peacock.win.seen`.
    public static let peacockWinSeen = EventTopic(rawValue: "peacock.win.seen")

    /// `peacock.clip.saved`.
    public static let peacockClipSaved = EventTopic(rawValue: "peacock.clip.saved")

    /// `peacock.kit.ready`.
    public static let peacockKitReady = EventTopic(rawValue: "peacock.kit.ready")

    /// `you.undo.asked`.
    public static let youUndoAsked = EventTopic(rawValue: "you.undo.asked")

    /// `you.correction.made`.
    public static let youCorrectionMade = EventTopic(rawValue: "you.correction.made")

    /// `app.ask.sent`.
    public static let appAskSent = EventTopic(rawValue: "app.ask.sent")

    /// `app.bird.paused`.
    public static let appBirdPaused = EventTopic(rawValue: "app.bird.paused")

    /// `app.bird.resumed`.
    public static let appBirdResumed = EventTopic(rawValue: "app.bird.resumed")

    /// Every topic in the contract's Topics table.
    public static let known: Set<EventTopic> = [
        owlPresenceChanged,
        owlFlowChanged,
        owlDistractionNoticed,
        owlNudgeGiven,
        owlScreenLocked,
        owlGestureDone,
        wrenFileMoved,
        wrenFileRenamed,
        wrenFileSkipped,
        wrenFolderCreated,
        wrenLookChanged,
        wrenModeChanged,
        wrenWorkspaceRestored,
        swiftRunStarted,
        swiftRunFinished,
        swiftTaskMerged,
        swiftTaskHeld,
        swiftTaskFailed,
        swiftMergeRolledBack,
        swiftReportReady,
        crowFrictionSeen,
        crowPitchMade,
        crowPitchAnswered,
        magpieNoteWritten,
        magpieNoteLinked,
        magpieLessonLearned,
        magpieMemoryForgotten,
        peacockWinSeen,
        peacockClipSaved,
        peacockKitReady,
        youUndoAsked,
        youCorrectionMade,
        appAskSent,
        appBirdPaused,
        appBirdResumed,
    ]
}
