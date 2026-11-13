import Foundation
import NestKit

/// Reads who a command is for: the picked bird, a bird named at the start ("Swift, build N1-15"), or everyone.
enum CommandText {
    static func parse(_ text: String, picked: Bird?) -> (recipient: String, words: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        for bird in Bird.allCases {
            for separator in [", ", " "] where trimmed.lowercased().hasPrefix(bird.rawValue + separator) {
                let words = String(trimmed.dropFirst(bird.rawValue.count + separator.count)).trimmingCharacters(in: .whitespaces)
                return (bird.rawValue, words)
            }
        }
        return (picked?.rawValue ?? "everyone", trimmed)
    }
}
