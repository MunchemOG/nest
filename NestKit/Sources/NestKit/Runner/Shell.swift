import Foundation

/// Runs command-line tools and hands back what they print.
public struct Shell: Sendable {
    /// A shell.
    public init() {}

    /// Runs `command` in `directory`, passing each printed line to `watch` as it appears, and waits for it to end.
    public func run(
        _ command: [String],
        in directory: URL,
        watch: @escaping @Sendable (String) -> Void = { _ in }
    ) async throws -> ShellOutput {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(with: Result { try Self.runAndWait(command, in: directory, watch: watch) })
            }
        }
    }

    private static func runAndWait(
        _ command: [String],
        in directory: URL,
        watch: (String) -> Void
    ) throws -> ShellOutput {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = command
        process.currentDirectoryURL = directory
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()

        var all = Data()
        var unfinished = Data()
        let newline = UInt8(ascii: "\n")
        while case let chunk = pipe.fileHandleForReading.availableData, !chunk.isEmpty {
            all.append(chunk)
            unfinished.append(chunk)
            while let end = unfinished.firstIndex(of: newline) {
                watch(String(decoding: unfinished[unfinished.startIndex..<end], as: UTF8.self))
                unfinished = Data(unfinished[unfinished.index(after: end)...])
            }
        }
        if !unfinished.isEmpty {
            watch(String(decoding: unfinished, as: UTF8.self))
        }
        process.waitUntilExit()
        return ShellOutput(status: process.terminationStatus, text: String(decoding: all, as: UTF8.self))
    }
}
