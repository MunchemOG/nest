import Foundation

/// A session as you see it: what you said, Claude's reply as it streams, each tool it used, each request, and each turn's end.
public struct SessionTranscript: Sendable, Equatable {
    /// The project's folder, so tool cards show paths inside it.
    public let folder: String
    /// Everything so far, oldest first.
    public private(set) var items: [TranscriptItem] = []
    /// What the session has cost so far, in US dollars.
    public private(set) var costUSD: Double = 0
    /// Whether Claude is working on a turn.
    public private(set) var isWorking = false
    private var counter = 0

    /// An empty transcript for a session in `folder`.
    public init(folder: String) {
        self.folder = folder
    }

    /// The request still waiting for your answer, if any.
    public var waiting: PermissionRequest? {
        items.last { $0.kind == .permission && $0.permission?.answer == nil }?.permission?.request
    }

    /// Adds what you said and marks the session working.
    public mutating func add(you text: String) {
        append(.you, text)
        isWorking = true
    }

    /// Records your answer to `request`.
    public mutating func answer(_ request: PermissionRequest, with answer: PermissionAnswer) {
        guard let index = items.lastIndex(where: { $0.permission?.request == request }) else { return }
        items[index].permission?.answer = answer
        if answer == .deny, let tool = items.lastIndex(where: { $0.kind == .tool && $0.tool?.status == .running }) {
            items[tool].tool?.status = .failed
        }
    }

    /// Folds one event from the session into the transcript.
    public mutating func apply(_ event: ClaudeEvent) {
        switch event {
        case .textDelta(let text):
            if let last = items.indices.last, items[last].kind == .claude, items[last].isStreaming {
                items[last].text += text
            } else {
                append(.claude, text, streaming: true)
            }
        case .text(_, let text):
            if let last = items.indices.last, items[last].kind == .claude, items[last].isStreaming {
                items[last].text = text
                items[last].isStreaming = false
            } else {
                append(.claude, text)
            }
        case .toolUse(let id, let name, let input):
            settleStreaming()
            var item = make(.tool, "")
            item.tool = ToolCard(id: id, name: name, summary: ToolCard.summary(tool: name, input: input, folder: folder),
                                 detail: ToolCard.detail(tool: name, input: input))
            items.append(item)
        case .toolResult(let id, let text, let isError):
            guard let index = items.lastIndex(where: { $0.tool?.id == id }) else { return }
            items[index].tool?.result = text
            items[index].tool?.status = isError ? .failed : .done
        case .permission(let request):
            var item = make(.permission, request.summary)
            item.permission = TranscriptItem.Permission(request: request, answer: nil)
            items.append(item)
        case .finished(let finish):
            settleStreaming()
            costUSD = finish.costUSD
            isWorking = false
            let text = finish.subtype == "error_during_execution" ? "Stopped."
                : finish.isError ? "Ended with an error." : String(format: "Done · $%.2f so far", finish.costUSD)
            append(.finished, text)
        case .ended:
            settleStreaming()
            isWorking = false
        case .started, .commands, .limits, .usage, .context, .account:
            break
        }
    }

    /// Marks the transcript at rest: nothing streaming, Claude not working; for a session read back from history.
    public mutating func settle() {
        settleStreaming()
        isWorking = false
    }

    private mutating func settleStreaming() {
        if let last = items.indices.last, items[last].isStreaming { items[last].isStreaming = false }
    }

    private mutating func append(_ kind: TranscriptItem.Kind, _ text: String, streaming: Bool = false) {
        var item = make(kind, text)
        item.isStreaming = streaming
        items.append(item)
    }

    private mutating func make(_ kind: TranscriptItem.Kind, _ text: String) -> TranscriptItem {
        counter += 1
        return TranscriptItem(id: "\(counter)", kind: kind, text: text, tool: nil, permission: nil, isStreaming: false)
    }
}
