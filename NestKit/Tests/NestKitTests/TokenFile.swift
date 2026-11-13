import Foundation

/// The parts of `design/tokens.json` that the token tests compare against.
struct TokenFile: Decodable {
    struct Token: Decodable {
        let name: String
        let value: String
    }

    struct Group: Decodable {
        let tokens: [Token]
    }

    struct TextStyle: Decodable {
        let name: String
        let fontSize: String
        let lineHeight: String
        let fontWeight: Int
        let letterSpacing: String?
        let sample: String
    }

    struct TextGroup: Decodable {
        let family: String
        let styles: [TextStyle]
    }

    struct TypeGroup: Decodable {
        let families: [String: String]
        let groups: [TextGroup]
    }

    let color: Group
    let spacing: Group
    let radius: Group
    let shadow: Group
    let duration: Group
    let easing: Group
    let type: TypeGroup

    /// The repository's `design/tokens.json`, found from this file's place in the repo.
    static let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "design/tokens.json")

    static func load() throws -> TokenFile {
        try JSONDecoder().decode(TokenFile.self, from: Data(contentsOf: url))
    }

    static func topLevelKeys() throws -> Set<String> {
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        return Set((object as? [String: Any] ?? [:]).keys)
    }
}
