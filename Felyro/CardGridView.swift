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

    @State private var searchText = ""
    @State private var selectedCard: Card?
    @State private var selectedCategory: CategoryType = .all
    @State private var isSelectionMode = false
    @State private var selectedCards = Set<Card>()
    @State private var showAddSheet = false
    @State private var showImporter = false
    @State private var isExporting = false
    @State private var exportData: Data?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                CardGridContentView(
                    searchText: $searchText,
                    selectedCard: $selectedCard,
                    selectedCategory: $selectedCategory,
                    isSelectionMode: $isSelectionMode,
                    selectedCards: $selectedCards
                )

                Button {
                    showAddSheet = true
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
            }
            .navigationDestination(item: $selectedCard) { card in
                CardDetailView(card: card)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        Menu {
                            Button {
                                    showImporter = true
                                } label: {
                                    Label(String(localized: "import"), systemImage: "square.and.arrow.down")
                                        .labelStyle(.titleAndIcon)
                                }
                            Button {
                                    exportAllCards()
                                } label: {
                                    Label(String(localized: "export"), systemImage: "square.and.arrow.up")
                                        .labelStyle(.titleAndIcon)
                                }
                            if isSelectionMode {
                                Button(role: .destructive) {
                                    deleteSelectedCards()
                                } label: {
                                    Label(String(localized: "delete"), systemImage: "trash")
                                        .labelStyle(.titleAndIcon)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }

                        Text(String(localized: "cards"))
                            .font(.title)
                            .bold()
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isSelectionMode {
                        Button(String(localized: "cancel")) {
                            isSelectionMode = false
                            selectedCards.removeAll()
                        }
                    }
                }
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "search_cards")
        )
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                AddCardView()
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let url = try result.get().first else { return }
                importCards(from: url)
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
            case .success: print("Export dokončen.")
            case .failure(let error): print("Export selhal: \(error)")
            }
        }
    }

    private func exportAllCards() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let request = FetchDescriptor<Card>(sortBy: [SortDescriptor(\.name)])

        do {
            let cards = try context.fetch(request)
            let dtos = cards.map { CardDTO(from: $0) }
            exportData = try encoder.encode(dtos)
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

    private func importCards(from url: URL) {
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
