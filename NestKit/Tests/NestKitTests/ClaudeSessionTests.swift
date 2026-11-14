import Foundation
import Testing
@testable import NestKit

struct ClaudeSessionTests {
    /// A stand-in for Claude Code's stream-json mode: it answers initialize, streams "Hello", asks to Write,
    /// waits for the answer, and stops a turn that says "count" when it is interrupted.
    static let standIn = #"""
    printf '%s\n' "$@" > args.txt
    echo '{"type":"system","subtype":"init","session_id":"s-1","model":"claude-sonnet-5-5","cwd":"here","permissionMode":"default"}'
    while IFS= read -r line; do
      case "$line" in
        *'"subtype":"initialize"'*)
          echo '{"type":"control_response","response":{"subtype":"success","request_id":"init","response":{"commands":[{"name":"compact","description":"Compact the chat"}]}}}' ;;
        *'"subtype":"interrupt"'*)
          echo '{"type":"result","subtype":"error_during_execution","is_error":true,"total_cost_usd":0.01,"session_id":"s-1"}' ;;
        *'"type":"user"'*)
          case "$line" in *count*)
            echo '{"type":"stream_event","event":{"type":"content_block_delta","delta":{"type":"text_delta","text":"1, 2"}}}'
            continue ;;
          esac
          echo '{"type":"stream_event","event":{"type":"content_block_delta","delta":{"type":"text_delta","text":"Hel"}}}'
          echo '{"type":"stream_event","event":{"type":"content_block_delta","delta":{"type":"text_delta","text":"lo"}}}'
          echo '{"type":"assistant","message":{"id":"m1","content":[{"type":"text","text":"Hello"}]}}'
          echo '{"type":"assistant","message":{"id":"m2","content":[{"type":"tool_use","id":"t1","name":"Write","input":{"file_path":"/w/hello.txt","content":"hi"}}]}}'
          echo '{"type":"control_request","request_id":"p1","request":{"subtype":"can_use_tool","tool_name":"Write","input":{"file_path":"/w/hello.txt","content":"hi"},"description":"hello.txt","permission_suggestions":[{"type":"setMode","mode":"acceptEdits","destination":"session"}]}}' ;;
        *'"type":"control_response"'*)
          printf '%s\n' "$line" > answer.txt
          echo '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1","content":"File created"}]}}'
          echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0.25,"session_id":"s-1"}' ;;
      esac
    done
    """#

    func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "ClaudeSessionTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let script = url.appending(path: "claude.sh")
        try ("#!/bin/sh\n" + Self.standIn + "\n").write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        return url
    }

    func options(_ folder: URL, model: ClaudeModel = .sonnet, effort: Effort = .high, mode: PermissionMode? = nil,
                 resume: String? = nil) -> ClaudeSession.Options {
        ClaudeSession.Options(folder: folder, model: model, effort: effort, mode: mode, resume: resume,
                              command: [folder.appending(path: "claude.sh").path])
    }

    /// Reads events until one matches `stop`, folding each into `transcript`.
    func read(_ events: inout AsyncStream<ClaudeEvent>.Iterator, into transcript: inout SessionTranscript,
              until stop: (ClaudeEvent) -> Bool) async -> [ClaudeEvent] {
        var seen: [ClaudeEvent] = []
        while let event = await events.next() {
            transcript.apply(event)
            seen.append(event)
            if stop(event) { break }
        }
        return seen
    }

    @Test func aSessionStreamsAsksPermissionAndFinishes() async throws {
        let folder = try folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = ClaudeSession(options(folder))
        var events = session.events.makeAsyncIterator()
        var transcript = SessionTranscript(folder: "/w")

        try await session.start()
        transcript.add(you: "make hello")
        try await session.send("make hello")
        let asked = await read(&events, into: &transcript) { if case .permission = $0 { true } else { false } }
        guard case .permission(let request)? = asked.last else { Issue.record("no permission asked"); return }
        #expect(request.tool == "Write")
        #expect(request.summary == "hello.txt")

        transcript.answer(request, with: .allow)
        try await session.answer(request, with: .allow)
        _ = await read(&events, into: &transcript) { if case .finished = $0 { true } else { false } }

        #expect(await session.sessionID == "s-1")
        #expect(await session.commands.map(\.name) == ["compact"])
        #expect(transcript.items.map(\.kind) == [.you, .claude, .tool, .permission, .finished])
        #expect(transcript.items[1].text == "Hello")
        #expect(transcript.items[2].tool?.summary == "hello.txt")
        #expect(transcript.items[2].tool?.result == "File created")
        #expect(transcript.items[2].tool?.status == .done)
        #expect(transcript.items[3].permission?.answer == .allow)
        #expect(transcript.costUSD == 0.25)
        let answer = try String(contentsOf: folder.appending(path: "answer.txt"), encoding: .utf8)
        #expect(answer.contains(#""behavior":"allow""#))
        #expect(answer.contains(#""request_id":"p1""#))
        await session.stop()
    }

    @Test func stoppingATurnInterruptsIt() async throws {
        let folder = try folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = ClaudeSession(options(folder))
        var events = session.events.makeAsyncIterator()
        var transcript = SessionTranscript(folder: "/w")
        try await session.start()

        transcript.add(you: "count to 100")
        try await session.send("count to 100")
        _ = await read(&events, into: &transcript) { if case .textDelta = $0 { true } else { false } }
        try await session.interrupt()
        _ = await read(&events, into: &transcript) { if case .finished = $0 { true } else { false } }

        #expect(transcript.items.last?.kind == .finished)
        #expect(transcript.items.last?.text == "Stopped.")
        #expect(transcript.items.first { $0.kind == .claude }?.text == "1, 2")
        await session.stop()
    }

    @Test func theSessionStartsWithYourModelEffortModeAndResume() async throws {
        let folder = try folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = ClaudeSession(options(folder, model: .opus, effort: .max, mode: .plan, resume: "s-0"))
        var events = session.events.makeAsyncIterator()
        try await session.start()
        _ = await events.next()

        let args = try String(contentsOf: folder.appending(path: "args.txt"), encoding: .utf8).split(separator: "\n").map(String.init)
        #expect(args.starts(with: ["-p", "--input-format", "stream-json", "--output-format", "stream-json", "--verbose",
                                   "--include-partial-messages", "--permission-prompt-tool", "stdio"]))
        #expect(args.contains { $0 == "--model" } && args[args.firstIndex(of: "--model")! + 1] == "opus")
        #expect(args[args.firstIndex(of: "--effort")! + 1] == "max")
        #expect(args[args.firstIndex(of: "--permission-mode")! + 1] == "plan")
        #expect(args[args.firstIndex(of: "--resume")! + 1] == "s-0")
        await session.stop()
    }

    @Test func ultracodeAddsTheKeywordOnce() {
        #expect(ClaudeSession.message("audit the budget", ultracode: true) == "ultracode audit the budget")
        #expect(ClaudeSession.message("ultracode: audit", ultracode: true) == "ultracode: audit")
        #expect(ClaudeSession.message("audit", ultracode: false) == "audit")
    }

    @Test func answersAreWrittenAsClaudeCodeExpects() throws {
        let request = PermissionRequest(id: "p9", tool: "Bash", input: .object(["command": .string("swift test")]),
                                        description: "Run tests",
                                        suggestions: [.object(["type": .string("addRules"), "behavior": .string("allow")])])
        let always = try #require(String(data: try JSONEncoder().encode(PermissionAnswer.allowAlways.response(to: request)), encoding: .utf8))
        #expect(always.contains(#""updatedPermissions":[{"#))
        #expect(always.contains(#""updatedInput":{"command":"swift test"}"#))
        let deny = try #require(String(data: try JSONEncoder().encode(PermissionAnswer.deny.response(to: request)), encoding: .utf8))
        #expect(deny.contains(#""behavior":"deny""#))
        #expect(request.summary == "swift test")
    }

    @Test func linesFromClaudeCodeAreRead() {
        #expect(ClaudeEvent(line: #"{"type":"system","subtype":"init","session_id":"abc","model":"claude-opus-5-5"}"#)
                == .started(sessionID: "abc", model: "claude-opus-5-5"))
        #expect(ClaudeEvent(line: #"{"type":"stream_event","event":{"type":"content_block_delta","delta":{"type":"text_delta","text":"Hi"}}}"#)
                == .textDelta("Hi"))
        #expect(ClaudeEvent(line: #"{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"t","content":[{"type":"text","text":"ok"}],"is_error":true}]}}"#)
                == .toolResult(id: "t", text: "ok", isError: true))
        #expect(ClaudeEvent(line: #"{"type":"rate_limit_event","rate_limit_info":{"unifiedWindows":{"five_hour":{"utilization":0.36,"resetsAt":1794689400},"seven_day":{"utilization":0.84,"resetsAt":1794693600}}}}"#)
                == .limits(LimitSnapshot(fiveHour: 0.36, fiveHourResets: Date(timeIntervalSince1970: 1_794_689_400),
                                         weekly: 0.84, weeklyResets: Date(timeIntervalSince1970: 1_794_693_600))))
        #expect(ClaudeEvent(line: "not json") == nil)
        #expect(ClaudeEvent(line: #"{"type":"system","subtype":"hook_started"}"#) == nil)
    }

    @Test func toolCardsSayWhatTheyTouchInTheProject() {
        #expect(ToolCard.summary(tool: "Edit", input: .object(["file_path": .string("/p/Sources/A.swift")]), folder: "/p") == "Sources/A.swift")
        #expect(ToolCard.summary(tool: "Bash", input: .object(["command": .string("swift test")]), folder: "/p") == "swift test")
        #expect(ToolCard.summary(tool: "Grep", input: .object(["pattern": .string("TODO")]), folder: "/p") == "TODO")
        #expect(ToolCard.summary(tool: "Mystery", input: .object([:]), folder: "/p") == "")
        let edit = ToolCard.detail(tool: "Edit", input: .object(["old_string": .string("a\nb"), "new_string": .string("c")]))
        #expect(edit == "- a\n- b\n+ c")
    }
}
