//
//  CardGridContentView.swift
//  Felyro
//
//  Created by Martin Horáček on 01.06.2025.
//
import SwiftUI
import SwiftData

struct CardGridContentView: View {
    @Binding var searchText: String
    @Binding var selectedCard: Card?
    @Binding var selectedCategory: CategoryType
    @Binding var isSelectionMode: Bool
    @Binding var selectedCards: Set<Card>

    @Query(sort: \Card.name) private var cards: [Card]

    var filteredCards: [Card] {
        cards.filter {
            (selectedCategory == .all || $0.category == selectedCategory) &&
            (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText))
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
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
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
                                        selectedCard = card
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
