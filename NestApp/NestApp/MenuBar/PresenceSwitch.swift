import NestKit
import Observation

/// The menu bar's "I'm here" switch: until Owl exists, flipping it publishes `owl.presence.changed` in Owl's name.
@MainActor
@Observable
final class PresenceSwitch {
    let model: HomeModel

    init(model: HomeModel) {
        self.model = model
    }

    /// Whether you said you are here; setting it publishes the change.
    var isHere: Bool {
        get { model.facts.presence == "here" }
        set {
            let was = model.facts.presence ?? (newValue ? "away" : "here")
            let to = newValue ? "here" : "away"
            guard to != was else { return }
            model.publish(.presenceChanged(to: to, was: was))
        }
    }
}
