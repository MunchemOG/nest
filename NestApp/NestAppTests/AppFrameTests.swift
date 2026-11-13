import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct AppFrameTests {
    @Test func theRailListsTheApprovedScreensInOrder() {
        #expect(NestScreen.allCases == [.home, .activity, .memory, .settings])
        #expect(NestScreen.allCases.map(\.title) == ["Home", "Activity", "Memory", "Settings"])
    }

    @Test func everyScreenHasItsOwnShortcutAndIds() {
        #expect(Set(NestScreen.allCases.map(\.shortcut)).count == NestScreen.allCases.count)
        for screen in NestScreen.allCases {
            #expect(screen.railID == "rail.\(screen.rawValue)")
            #expect(screen.screenID == "screen.\(screen.rawValue)")
        }
    }

    @Test func onlySettingsSitsBelowTheDivider() {
        #expect(NestScreen.allCases.filter(\.isBelowDivider) == [.settings])
    }

    @Test func railButtonsComeFromTokens() {
        #expect(RailButtonPalette(isSelected: false, isHovered: false).icon == .textMuted)
        #expect(RailButtonPalette(isSelected: false, isHovered: true).icon == .textPrimary)
        #expect(RailButtonPalette(isSelected: true, isHovered: false).fill == .surface3)
        #expect(RailButtonPalette(isSelected: true, isHovered: false).marker == .clay)
        #expect(RailButtonPalette(isSelected: false, isHovered: false).marker == nil)
    }

    @Test(arguments: NestScreen.allCases)
    func theRailMatchesItsSnapshotForEachScreen(_ screen: NestScreen) throws {
        try Snapshot.expect(Rail(selection: .constant(screen)), named: "rail-\(screen.rawValue)")
    }
}
