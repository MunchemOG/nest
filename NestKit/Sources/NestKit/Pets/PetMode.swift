/// How the pets are behaving overall.
public enum PetMode: Hashable, Sendable {
    /// Now and then one idle bird visits.
    case visitor
    /// After a long work streak, two or three birds keep Mithun company.
    case breakBuddy
    /// Nobody is at the Mac, so every idle bird is out.
    case lively
    /// Something says no pets: every bird stays home.
    case hidden
}
