import NestKit
import SwiftUI

/// A column of cards where clicking one selects it and unselects the rest.
struct NestCardList<Item: Identifiable, Row: View>: View {
    let items: [Item]
    @Binding var selection: CardSelection<Item.ID>
    let bird: (Item) -> Bird?
    let row: (Item) -> Row

    init(
        _ items: [Item],
        selection: Binding<CardSelection<Item.ID>>,
        bird: @escaping (Item) -> Bird? = { _ in nil },
        @ViewBuilder row: @escaping (Item) -> Row
    ) {
        self.items = items
        self._selection = selection
        self.bird = bird
        self.row = row
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NestSpace.s3) {
            ForEach(items) { item in
                Button { selection.select(item.id) } label: { row(item) }
                    .buttonStyle(NestCardStyle(bird: bird(item), isSelected: selection.isSelected(item.id)))
            }
        }
    }
}
