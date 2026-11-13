import NestKit
import SwiftUI

extension Animation {
    /// An animation that runs for a duration token along an easing token.
    static func nest(_ duration: Duration, _ curve: NestMotion.Curve = NestMotion.easeOut) -> Animation {
        let seconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        return .timingCurve(curve.x1, curve.y1, curve.x2, curve.y2, duration: seconds)
    }
}
