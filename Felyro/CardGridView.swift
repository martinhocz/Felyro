//
//  CardGridView.swift
//  Felyro
//
//  Created by Martin Horáček on 28.05.2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CardGridView: View {
    @Environment(\.modelContext) private var context
    @State private var showImporter = false
    @State private var exportData: Data?
    @State private var isExporting = false

    @State private var isSelectionMode = false
    @State private var selectedCards = Set<Card>()
    @State private var searchText = ""
    @State private var selectedCategory: CategoryType = .all
    @State private var showMenu = false
    @State private var showDeleteConfirmation = false

    @Query(sort: \Card.name) var cards: [Card]

    var filteredCards: [Card] {
        cards.filter { card in
            (selectedCategory == .all || card.category == selectedCategory) &&
            (searchText.isEmpty || card.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(CategoryType.allCases) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
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
                    .pickerStyle(.segmented)
                    .padding([.horizontal, .top])

                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                            ForEach(filteredCards) { card in
                                Group {
                                    if isSelectionMode {
                                        CardTileView(card: card, isSelected: selectedCards.contains(card))
                                            .onTapGesture {
                                                toggleSelection(for: card)
                                            }
                                    } else {
                                        ZStack {
                                            NavigationLink(destination: CardDetailView(card: card)) {
                                                CardTileView(card: card)
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .simultaneousGesture(LongPressGesture().onEnded { _ in
                                            isSelectionMode = true
                                            toggleSelection(for: card)
                                        })
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        for card in cards {
                            // Pokud nějaká karta má nevyplněnou kategorii (např. importovaná dříve)
                            // přiřadíme jí výchozí hodnotu
                            if Mirror(reflecting: card).children.first(where: { $0.label == "category" }) == nil {
                                card.category = .other
                            }
                        }
                    }
                }
                //.navigationTitle("Karty")
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Hledat kartu")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack(spacing: 8) {
                            Menu {
                                Button("Import") { showImporter = true }
                                Button("Export", action: exportAllCards)
                            } label: {
                                Image(systemName: "line.3.horizontal")
                            }

                            Text("Karty")
                                .font(.title)
                                .bold()
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if isSelectionMode {
                            Button("Smazat", role: .destructive) {
                                deleteSelectedCards()
                            }
                            .foregroundColor(.red)
                            Button("Zrušit") {
                                isSelectionMode = false
                                selectedCards.removeAll()
                            }
                        }
                    }

                }

                Button {
                    showMenu = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
                .sheet(isPresented: $showMenu) {
                    NavigationStack {
                        AddCardView()
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let url = try result.get().first else { return }
                importCards(from: url, into: context)
            } catch {
                print("Import selhal: \(error)")
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportData.map { ExportedFile(data: $0) },
            contentType: .json,
            defaultFilename: "cards"
        ) { result in
            switch result {
            case .success:
                print("Export dokončen.")
            case .failure(let error):
                print("Export selhal: \(error)")
            }
        }
    }

    private func toggleSelection(for card: Card) {
        if selectedCards.contains(card) {
            selectedCards.remove(card)
        } else {
            selectedCards.insert(card)
        }
    }

    private func exportAllCards() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let dtos = cards.map { CardDTO(from: $0) }

        do {
            let data = try encoder.encode(dtos)
            exportData = data
            isExporting = true
        } catch {
            print("Export selhal: \(error)")
        }
    }

    private func exportSelectedCards() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let dtos = selectedCards.map { CardDTO(from: $0) }

        do {
            let data = try encoder.encode(dtos)
            exportData = data
            isExporting = true
        } catch {
            print("Export selhal: \(error)")
        }
    }

    private func deleteSelectedCards() {
        for card in selectedCards {
            context.delete(card)
        }
        selectedCards.removeAll()
        isSelectionMode = false
    }

    private func importCards(from url: URL, into context: ModelContext) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let dtos = try decoder.decode([CardDTO].self, from: data)

            for dto in dtos {
                context.insert(dto.toCard())
            }
        } catch {
            print("Import selhal: \(error)")
        }
    }
}
