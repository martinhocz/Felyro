import SwiftUI
import SwiftData

struct CardGridContentView: View {
    @Binding var selectedCardForDetail: Card?
    @Binding var searchText: String
    @Binding var isSelectionMode: Bool
    @Binding var selectedCards: Set<Card>
    @Binding var selectedCategory: CategoryType

    @Query(sort: \Card.name) private var cards: [Card]

    var filteredCards: [Card] {
        cards.filter { card in
            (selectedCategory == .all || card.category == selectedCategory) &&
            (searchText.isEmpty || card.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(CategoryType.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category.displayName)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(selectedCategory == category ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                                .foregroundColor(selectedCategory == category ? .accentColor : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                    ForEach(filteredCards) { card in
                        Group {
                            if isSelectionMode {
                                CardTileView(card: card, isSelected: selectedCards.contains(card))
                                    .onTapGesture {
                                        toggleSelection(card)
                                    }
                            } else {
                                CardTileView(card: card)
                                    .onTapGesture {
                                        selectedCardForDetail = card
                                    }
                                    .onLongPressGesture {
                                        isSelectionMode = true
                                        toggleSelection(card)
                                    }
                            }
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                for card in cards {
                    if Mirror(reflecting: card).children.first(where: { $0.label == "category" }) == nil {
                        card.category = .other
                    }
                }
            }
        }
    }

    private func toggleSelection(_ card: Card) {
        if selectedCards.contains(card) {
            selectedCards.remove(card)
        } else {
            selectedCards.insert(card)
        }
    }
}
