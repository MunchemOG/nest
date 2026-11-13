import NestKit
import SwiftUI

/// Everything every bird did, newest first, by day, with filters, search and one-tap Undo.
struct TimelineScreen: View {
    let model: HomeModel
    @State var query: TimelineQuery

    @Environment(\.timeZone) private var timeZone
    @Environment(\.locale) private var locale

    init(model: HomeModel, query: TimelineQuery = TimelineQuery()) {
        self.model = model
        self._query = State(initialValue: query)
    }

    var body: some View {
        let days = TimelineQuery.groups(model.events, matching: query, in: timeZone)
        VStack(alignment: .leading, spacing: NestSpace.s5) {
            Text(NestScreen.activity.title)
                .nestFont(.displayL)
                .foregroundStyle(Color(NestColor.textPrimary))
            HStack(spacing: NestSpace.s4) {
                TimelineSearchField(text: $query.text)
                    .frame(width: HomeLayout.column)
                TimelineFilters(bird: $query.bird)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: NestSpace.s5) {
                    ForEach(days, id: \.day) { day in
                        VStack(alignment: .leading, spacing: NestSpace.s2) {
                            Text(day.title(locale: locale))
                                .nestFont(.caption)
                                .foregroundStyle(Color(NestColor.textMuted))
                            NestPanel(.solid, padding: NestSpace.s2) {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(day.events, id: \.id) { event in
                                        ActivityRow(event, isUndone: model.isUndone(event), publish: model.publish)
                                            .accessibilityIdentifier("timeline.row")
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    if days.isEmpty {
                        Text("Nothing matches.")
                            .nestFont(.bodyS)
                            .foregroundStyle(Color(NestColor.textMuted))
                    }
                }
            }
            .scrollIndicators(.never)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(NestScreen.activity.screenID)
    }
}
