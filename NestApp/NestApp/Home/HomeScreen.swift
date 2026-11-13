import NestKit
import SwiftUI

/// Home, over the flock: the headline, the date and mode, focus, what needs you, live activity and the command bar.
struct HomeScreen: View {
    let model: HomeModel

    @Environment(\.timeZone) private var timeZone

    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                HStack(alignment: .top, spacing: NestSpace.s6) {
                    HeadlineView(headline: model.headline)
                    Spacer(minLength: 0)
                    HomeTopBar(now: model.now, mode: model.facts.mode ?? "Night", switchMode: model.switchMode)
                }
            }
            .overlay(alignment: .topTrailing) {
                VStack(alignment: .trailing, spacing: NestSpace.s3) {
                    if let focus {
                        focus.frame(width: HomeLayout.column)
                    }
                    NeedsYouPanel(events: model.needsYou, answer: model.answer)
                        .frame(width: HomeLayout.column)
                }
                .padding(.top, NestSpace.s9 - NestSpace.s4)
            }
            .overlay(alignment: .bottomLeading) {
                ActivityPanel(model: model)
                    .frame(width: HomeLayout.column)
            }
            .overlay {
                GeometryReader { space in
                    let dock = HomeLayout.dock(inContentWidth: space.size.width)
                    CommandBar(send: model.send, width: dock.width)
                        .position(x: dock.centre, y: space.size.height - NestSpace.s7 / 2 - NestSpace.s2)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(NestScreen.home.screenID)
    }

    private var focus: FocusWidget? {
        guard let until = model.facts.focusUntil, let since = model.facts.modeSince, let now = model.now,
              let progress = FocusProgress(since: since, until: until, now: now, timeZone: timeZone) else { return nil }
        return FocusWidget(until: until, progress: progress, notificationsOff: model.facts.notificationsOff)
    }
}
