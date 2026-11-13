import NestKit

/// What a status pill reports: a bird's status, or a plain outcome.
enum StatusPillKind: Hashable, Sendable {
    /// How one bird is doing.
    case bird(Bird, BirdStatus)
    /// Shipped, passed, done.
    case success(String)
    /// Needs a look.
    case warning(String)
    /// Failed.
    case danger(String)

    /// The word shown.
    var word: String {
        switch self {
        case .bird(_, .asleep): "Asleep"
        case .bird(_, .resting): "Resting"
        case .bird(_, .active): "Working"
        case .bird(_, .paused): "Paused"
        case .success(let word), .warning(let word), .danger(let word): word
        }
    }

    /// The SF Symbol shown before the word; nil shows a dot.
    var symbol: String? {
        switch self {
        case .bird(_, .asleep): "moon.zzz.fill"
        case .bird(_, .paused): "pause.fill"
        case .bird: nil
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .danger: "xmark.octagon.fill"
        }
    }

    /// The colour of the dot or icon.
    var accent: NestColor {
        switch self {
        case .bird(let bird, .active): bird.color
        case .bird(_, .paused): .statusWarning
        case .bird: .textMuted
        case .success: .statusSuccess
        case .warning: .statusWarning
        case .danger: .statusDanger
        }
    }

    /// The colour the dot fades to while breathing.
    var accentRest: NestColor {
        if case .bird(let bird, .active) = self { bird.tint } else { accent }
    }

    /// The colour of the word.
    var label: NestColor {
        switch self {
        case .bird(_, .active): .textPrimary
        case .bird(_, .resting): .textSecondary
        case .bird(_, .asleep): .textMuted
        case .bird(_, .paused): .statusWarning
        case .success, .warning, .danger: .textPrimary
        }
    }

    /// Whether the dot breathes: only for a working bird, and never under reduced motion.
    func breathes(reduceMotion: Bool) -> Bool {
        guard !reduceMotion, case .bird(_, .active) = self else { return false }
        return true
    }
}
