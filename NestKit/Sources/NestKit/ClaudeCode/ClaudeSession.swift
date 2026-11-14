import Foundation

/// One live Claude Code session in a project's folder: the real `claude`, driven over its stream-json protocol,
/// exactly as its own SDK drives it. Swift adds nothing to what Claude Code does.
public actor ClaudeSession {
    /// How a session starts.
    public struct Options: Sendable, Equatable {
        /// The project's folder; Claude Code runs inside it.
        public var folder: URL
        /// The model.
        public var model: ClaudeModel
        /// How hard it thinks.
        public var effort: Effort
        /// How it asks before acting, or nil for your Claude Code settings' default.
        public var mode: PermissionMode?
        /// The session to resume, or nil for a new one.
        public var resume: String?
        /// The command that starts Claude Code; the session's arguments follow it.
        public var command: [String]

        /// Options for a session in `folder`.
        public init(folder: URL, model: ClaudeModel, effort: Effort, mode: PermissionMode? = nil, resume: String? = nil,
                    command: [String] = ClaudeSession.claude) {
            self.folder = folder
            self.model = model
            self.effort = effort
            self.mode = mode
            self.resume = resume
            self.command = command
        }

        /// The arguments Claude Code is started with.
        public var arguments: [String] {
            ["-p", "--input-format", "stream-json", "--output-format", "stream-json", "--verbose", "--include-partial-messages",
             "--permission-prompt-tool", "stdio", "--model", model.rawValue, "--effort", effort.rawValue]
                + (mode.map { ["--permission-mode", $0.rawValue] } ?? [])
                + (resume.map { ["--resume", $0] } ?? [])
        }
    }

    /// The command that starts the real Claude Code. Apps get a bare PATH, so the places it installs to come first.
    public static let claude = [
        "/bin/sh", "-c", #"PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH" exec claude "$@""#, "claude",
    ]

    /// How the session started.
    public let options: Options
    /// Everything the session says, in order; it ends when the process does.
    public nonisolated let events: AsyncStream<ClaudeEvent>
    /// The session's id, once Claude Code has said it.
    public private(set) var sessionID: String?
    /// Claude Code's slash commands, once it is ready.
    public private(set) var commands: [SlashCommand] = []

    private let continuation: AsyncStream<ClaudeEvent>.Continuation
    private var process: Process?
    private var input: FileHandle?
    private var requests = 0

    /// A session that will start with `options`.
    public init(_ options: Options) {
        self.options = options
        (events, continuation) = AsyncStream.makeStream(of: ClaudeEvent.self)
    }

    /// Starts Claude Code and asks it for its commands.
    public func start() throws {
        guard process == nil else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: options.command[0])
        process.arguments = Array(options.command.dropFirst()) + options.arguments
        process.currentDirectoryURL = options.folder
        let stdin = Pipe(), stdout = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = FileHandle.nullDevice
        let continuation = continuation
        process.terminationHandler = { continuation.yield(.ended($0.terminationStatus)) ; continuation.finish() }
        try process.run()
        self.process = process
        input = stdin.fileHandleForWriting
        Task { [weak self] in
            do {
                for try await line in stdout.fileHandleForReading.bytes.lines {
                    guard let event = ClaudeEvent(line: line) else { continue }
                    await self?.heard(event)
                    continuation.yield(event)
                }
            } catch {}
        }
        try control(["subtype": .string("initialize"), "hooks": .null])
    }

    /// Sends what you typed as your next message.
    public func send(_ text: String) throws {
        try write(.object([
            "type": .string("user"),
            "message": .object(["role": .string("user"), "content": .string(text)]),
            "parent_tool_use_id": .null,
            "session_id": .string(sessionID ?? "default"),
        ]))
    }

    /// Answers a permission request.
    public func answer(_ request: PermissionRequest, with answer: PermissionAnswer) throws {
        try write(.object([
            "type": .string("control_response"),
            "response": .object(["subtype": .string("success"), "request_id": .string(request.id),
                                 "response": answer.response(to: request)]),
        ]))
    }

    /// Stops the turn Claude is working on, as Escape does in the terminal.
    public func interrupt() throws {
        try control(["subtype": .string("interrupt")])
    }

    /// Switches the model for the rest of the session.
    public func setModel(_ model: ClaudeModel) throws {
        try control(["subtype": .string("set_model"), "model": .string(model.rawValue)])
    }

    /// Switches how Claude Code asks before acting.
    public func setMode(_ mode: PermissionMode) throws {
        try control(["subtype": .string("set_permission_mode"), "mode": .string(mode.rawValue)])
    }

    /// Ends the session's process.
    public func stop() {
        try? input?.close()
        process?.terminate()
        process = nil
    }

    /// What you send with Ultracode on: your message with Claude Code's `ultracode` keyword in front, unless it has it already.
    public static func message(_ text: String, ultracode: Bool) -> String {
        guard ultracode, !text.lowercased().contains("ultracode") else { return text }
        return "ultracode " + text
    }

    private func heard(_ event: ClaudeEvent) {
        switch event {
        case .started(let id, _): sessionID = id
        case .finished(let finish): sessionID = finish.sessionID ?? sessionID
        case .commands(let list): commands = list
        default: break
        }
    }

    private func control(_ request: [String: JSONValue]) throws {
        requests += 1
        try write(.object(["type": .string("control_request"), "request_id": .string("swift-\(requests)"), "request": .object(request)]))
    }

    private func write(_ message: JSONValue) throws {
        guard let input else { throw ClaudeSessionError.notStarted }
        try input.write(contentsOf: JSONEncoder().encode(message) + Data("\n".utf8))
    }
}
