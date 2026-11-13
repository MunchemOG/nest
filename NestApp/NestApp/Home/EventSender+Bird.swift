import NestKit

extension EventSender {
    /// The bird that sent it, if a bird did.
    var bird: Bird? {
        if case .bird(let bird) = self { bird } else { nil }
    }
}
