import SwiftUI

extension EnvironmentValues {
    /// Forces reduced motion on or off for previews and tests; nil follows the system setting.
    @Entry var reduceMotionOverride: Bool? = nil
}
