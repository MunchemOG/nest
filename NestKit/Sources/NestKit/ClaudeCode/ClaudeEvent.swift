import Foundation

/// One thing a Claude Code session said, read from a line of its stream-json output.
public enum ClaudeEvent: Sendable, Equatable {
    /// The session started, with its id and model.
    case started(sessionID: String, model: String)
    /// Claude Code's slash commands, sent once it is ready.
    case commands([SlashCommand])
    /// A piece of Claude's reply as it is written.
    case textDelta(String)
    /// A finished block of Claude's reply.
    case text(id: String, text: String)
    /// Claude calling a tool.
    case toolUse(id: String, name: String, input: JSONValue)
    /// What a tool gave back.
    case toolResult(id: String, text: String, isError: Bool)
    /// Claude asking to use a tool.
    case permission(PermissionRequest)
    /// How full your plan's limits are, from the stream after a request.
    case limits(LimitSnapshot)
    /// Claude Code's own report of your plan, each limit with its reset, and the session's totals.
    case usage(ClaudeUsage)
    /// How full the session's context is.
    case context(ContextUsage)
    /// Who is signed in.
    case account(ClaudeAccount)
    /// A turn ended.
    case finished(SessionFinish)
    /// The process ended, with its exit status.
    case ended(Int32)

    /// Every event in `line`, in order: Claude Code's answer to `initialize` holds both its commands and the account.
    public static func all(in line: String) -> [ClaudeEvent] {
        guard let first = ClaudeEvent(line: line) else { return [] }
        guard case .commands = first, let account = JSONValue(line: line)?["response"]?["response"]?["account"],
              account["email"] != nil || account["subscriptionType"] != nil else { return [first] }
        return [first, .account(ClaudeAccount(email: account["email"]?.string, plan: account["subscriptionType"]?.string))]
    }

    /// The first event in `line`, or nil if the line is not one Swift shows.
    public init?(line: String) {
        guard let json = JSONValue(line: line), let type = json["type"]?.string else { return nil }
        switch type {
        case "system":
            guard json["subtype"]?.string == "init", let id = json["session_id"]?.string else { return nil }
            self = .started(sessionID: id, model: json["model"]?.string ?? "")
        case "control_response":
            guard let response = json["response"]?["response"] else { return nil }
            if let usage = ClaudeUsage(response) { self = .usage(usage); return }
            if let context = ContextUsage(response) { self = .context(context); return }
            guard let list = response["commands"]?.array else { return nil }
            self = .commands(list.compactMap { command in
                command["name"]?.string.map { SlashCommand(name: $0, description: command["description"]?.string ?? "") }
            })
        case "stream_event":
            guard let delta = json["event"]?["delta"], delta["type"]?.string == "text_delta", let text = delta["text"]?.string else {
                return nil
            }
            self = .textDelta(text)
        case "assistant":
            guard let block = json["message"]?["content"]?.array?.first else { return nil }
            switch block["type"]?.string {
            case "text":
                guard let text = block["text"]?.string else { return nil }
                self = .text(id: json["message"]?["id"]?.string ?? "", text: text)
            case "tool_use":
                guard let id = block["id"]?.string, let name = block["name"]?.string else { return nil }
                self = .toolUse(id: id, name: name, input: block["input"] ?? .object([:]))
            default:
                return nil
            }
        case "user":
            guard let block = json["message"]?["content"]?.array?.first, block["type"]?.string == "tool_result",
                  let id = block["tool_use_id"]?.string else { return nil }
            let content = block["content"]
            let text = content?.string
                ?? content?.array?.compactMap { $0["text"]?.string }.joined(separator: "\n")
                ?? ""
            self = .toolResult(id: id, text: text, isError: block["is_error"] == .bool(true))
        case "control_request":
            guard let request = json["request"], request["subtype"]?.string == "can_use_tool",
                  let id = json["request_id"]?.string, let tool = request["tool_name"]?.string else { return nil }
            self = .permission(PermissionRequest(id: id, tool: tool, input: request["input"] ?? .object([:]),
                                                 description: request["description"]?.string ?? "",
                                                 suggestions: request["permission_suggestions"]?.array ?? []))
        case "rate_limit_event":
            guard let windows = json["rate_limit_info"]?["unifiedWindows"],
                  let five = windows["five_hour"]?["utilization"]?.number, let fiveResets = windows["five_hour"]?["resetsAt"]?.number,
                  let week = windows["seven_day"]?["utilization"]?.number, let weekResets = windows["seven_day"]?["resetsAt"]?.number
            else { return nil }
            self = .limits(LimitSnapshot(fiveHour: five, fiveHourResets: Date(timeIntervalSince1970: fiveResets),
                                         weekly: week, weeklyResets: Date(timeIntervalSince1970: weekResets)))
        case "result":
            self = .finished(SessionFinish(subtype: json["subtype"]?.string ?? "", isError: json["is_error"] == .bool(true),
                                           costUSD: json["total_cost_usd"]?.number ?? 0, sessionID: json["session_id"]?.string))
        default:
            return nil
        }
    }
}
