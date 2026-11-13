import Foundation

/// Finds colours, fonts, sizes, radii and timings written as literals in view code instead of taken from the tokens.
public enum DesignLiteralCheck {
    /// A number other than zero.
    private static let number = #"-?(?:[1-9][0-9]*(?:\.[0-9]+)?|0\.[0-9]*[1-9][0-9]*)"#

    /// Each pattern is one kind of literal the tokens should supply.
    static let patterns: [String] = [
        #"\b(?:Color|NSColor|UIColor)\((?:red|white|hue|hex|\.sRGB|calibratedRed|srgbRed|deviceRed)\b"#,
        #"#colorLiteral"#,
        ##""#[0-9a-fA-F]{3,8}""##,
        #"\.system\(size:"#,
        #"\.custom\(""#,
        #"\b(?:padding|spacing|cornerRadius|radius|width|height|size|duration|lineWidth|minLength|blur|x|y)\s*:\s*"# + number + #"\b"#,
        #"\.padding\(\s*"# + number,
        #"\.(?:easeIn|easeOut|easeInOut|linear|spring|bouncy|snappy|smooth)\("#,
    ]

    /// One line per literal found, as `path: line`.
    public static func problems(in diff: BranchDiff) -> [String] {
        diff.files.filter(isViewCode).flatMap { file in
            file.added
                .filter { line in patterns.contains { line.range(of: $0, options: .regularExpression) != nil } }
                .map { "\(file.path): \($0.trimmingCharacters(in: .whitespaces))" }
        }
    }

    /// The app's own Swift code, apart from the tokens, which is where literals belong.
    static func isViewCode(_ file: ChangedFile) -> Bool {
        file.isSource && file.path.hasPrefix("NestApp/NestApp/") && !file.path.hasPrefix("NestApp/NestApp/Tokens/")
    }
}
