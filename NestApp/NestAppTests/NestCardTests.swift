import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct NestCardTests {
    struct Item: Identifiable, Hashable {
        let id: String
        let bird: Bird
    }

    static let items = [Item(id: "a", bird: .wren), Item(id: "b", bird: .swift), Item(id: "c", bird: .owl)]

    @Test func onlyOneCardInAListCanBeSelected() {
        var selection = CardSelection<String>()
        selection.select("a")
        selection.select("b")
        let selected = Self.items.filter { selection.isSelected($0.id) }
        #expect(selected.map(\.id) == ["b"])
    }

    @Test func selectingTheSelectedCardKeepsIt() {
        var selection = CardSelection<String>()
        selection.select("a")
        selection.select("a")
        #expect(selection.isSelected("a"))
    }

    @Test func clearingLeavesNothingSelected() {
        var selection = CardSelection<String>(selected: "c")
        selection.clear()
        #expect(Self.items.allSatisfy { !selection.isSelected($0.id) })
    }

    @Test func statesComeFromTokens() {
        #expect(NestCardPalette(.rest).fill == .surface1 && NestCardPalette(.rest).border == .line)
        #expect(NestCardPalette(.hover).fill == .surface2 && NestCardPalette(.hover).border == .lineStrong)
        #expect(NestCardPalette(.pressed).fill == .surface3)
        #expect(NestCardPalette(.selected).border == .clay)
        #expect(NestCardState.selected.isSelected && !NestCardState.rest.isSelected)
    }

    @Test(arguments: Bird.allCases)
    func aBirdCardWashesOnlyInThatBirdsTint(_ bird: Bird) {
        #expect(NestCardFace(bird: bird, state: .rest) { Text("x") }.wash == bird.tint)
        #expect(NestCardFace(bird: nil, state: .rest) { Text("x") }.wash == nil)
    }

    static func sample(_ bird: Bird?) -> some View {
        VStack(alignment: .leading, spacing: NestSpace.s1) {
            Text("Crow pitched a tool that names STEP exports").nestFont(.bodyS).foregroundStyle(Color(NestColor.textPrimary))
            Text("Crow · 11:04").nestFont(.caption).foregroundStyle(Color(NestColor.textMuted))
        }
        .frame(width: NestSpace.s10 * 2, alignment: .leading)
    }

    static let states: [(String, NestCardState)] = [
        ("rest", .rest), ("hover", .hover), ("pressed", .pressed), ("selected", .selected), ("focused", .focused),
    ]

    @Test func everyStateMatchesItsSnapshot() throws {
        for (name, state) in Self.states {
            try Snapshot.expect(NestCardFace(bird: nil, state: state) { Self.sample(nil) }, named: "card-\(name)")
            try Snapshot.expect(NestCardFace(bird: .crow, state: state) { Self.sample(.crow) }, named: "card-crow-\(name)")
        }
    }

    @Test func aListShowsItsOneSelectedCard() throws {
        let list = NestCardList(Self.items, selection: .constant(CardSelection(selected: "b")), bird: \.bird) { item in
            Text(item.bird.name).nestFont(.body).foregroundStyle(Color(NestColor.textPrimary))
                .frame(width: NestSpace.s10 * 2, alignment: .leading)
        }
        try Snapshot.expect(list, named: "card-list-one-selected")
    }
}
