import Foundation
@testable import NestKit

/// Reads the CSS-style strings in `tokens.json`, independently of the Swift token values.
enum CSSValue {
    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    /// `#rrggbb` or `#rrggbbaa`.
    static func color(_ text: String) throws -> NestColor {
        guard text.hasPrefix("#"), let number = UInt32(text.dropFirst(), radix: 16) else {
            throw Failure(description: "not a hex colour: \(text)")
        }
        switch text.count {
        case 7: return NestColor(rgb: number)
        case 9: return NestColor(rgba: number)
        default: throw Failure(description: "not a hex colour: \(text)")
        }
    }

    /// `12px`, or a bare `0`.
    static func length(_ text: String) throws -> Double {
        let digits = text.hasSuffix("px") ? String(text.dropLast(2)) : text
        guard let value = Double(digits), text.hasSuffix("px") || value == 0 else {
            throw Failure(description: "not a length: \(text)")
        }
        return value
    }

    /// `-0.01em`.
    static func em(_ text: String) throws -> Double {
        guard text.hasSuffix("em"), let value = Double(text.dropLast(2)) else {
            throw Failure(description: "not an em length: \(text)")
        }
        return value
    }

    /// `80ms`.
    static func duration(_ text: String) throws -> Duration {
        guard text.hasSuffix("ms"), let value = Int(text.dropLast(2)) else {
            throw Failure(description: "not a duration: \(text)")
        }
        return .milliseconds(value)
    }

    /// `cubic-bezier(x1, y1, x2, y2)`.
    static func curve(_ text: String) throws -> NestMotion.Curve {
        guard text.hasPrefix("cubic-bezier("), text.hasSuffix(")") else {
            throw Failure(description: "not a cubic-bezier: \(text)")
        }
        let numbers = text.dropFirst("cubic-bezier(".count).dropLast()
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard numbers.count == 4 else {
            throw Failure(description: "not a cubic-bezier: \(text)")
        }
        return NestMotion.Curve(x1: numbers[0], y1: numbers[1], x2: numbers[2], y2: numbers[3])
    }

    /// Comma-separated layers of `[inset] x y [blur [spread]] colour`.
    static func shadow(_ text: String) throws -> NestShadow {
        let layers = try text.split(separator: ",").map { part in
            var words = part.split(separator: " ").map(String.init)
            let inset = words.first == "inset"
            if inset { words.removeFirst() }
            guard let colorWord = words.popLast(), (2...4).contains(words.count) else {
                throw Failure(description: "not a shadow layer: \(part)")
            }
            let lengths = try words.map(length) + Array(repeating: 0, count: 4 - words.count)
            return NestShadow.Layer(
                inset: inset,
                x: lengths[0],
                y: lengths[1],
                blur: lengths[2],
                spread: lengths[3],
                color: try color(colorWord)
            )
        }
        return NestShadow(layers: layers)
    }
}
