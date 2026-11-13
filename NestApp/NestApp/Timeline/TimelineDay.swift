import Foundation
import NestKit

/// One day's rows in the timeline, newest first.
struct TimelineDay: Hashable, Sendable {
    /// Midnight at the start of the day.
    let day: Date
    let timeZone: TimeZone
    var events: [NestEvent]

    /// "Tuesday, November 10".
    func title(locale: Locale) -> String {
        day.formatted(Date.FormatStyle(locale: locale, timeZone: timeZone).weekday(.wide).month(.wide).day())
    }
}
