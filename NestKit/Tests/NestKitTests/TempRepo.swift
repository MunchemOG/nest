import Foundation
@testable import NestKit

/// A throwaway git repository in the temp folder, with one commit on main and a stand-in for Claude Code.
struct TempRepo {
    let url: URL

    init() async throws {
        url = FileManager.default.temporaryDirectory.appending(path: "nest-runner-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try await git("init", "-q", "-b", "main")
        try await git("config", "user.name", "Nest Tests")
        try await git("config", "user.email", "tests@nest.invalid")
        try await git("config", "commit.gpgsign", "false")
        try "A nest.\n".write(to: url.appending(path: "README.md"), atomically: true, encoding: .utf8)
        try await git("add", ".")
        try await git("commit", "-q", "-m", "Start")
    }

    /// Runs git in the repository and returns what it printed.
    @discardableResult
    func git(_ arguments: String...) async throws -> String {
        let output = try await Shell().run(["git"] + arguments, in: url)
        guard output.succeeded else { throw CocoaError(.fileWriteUnknown) }
        return output.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Writes an executable shell script outside the work tree's tracked files and returns the command that runs it.
    func script(_ name: String, _ body: String) throws -> [String] {
        let file = url.appending(path: ".git/\(name)")
        try "#!/bin/sh\n\(body)\n".write(to: file, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: file.path)
        return [file.path]
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}
