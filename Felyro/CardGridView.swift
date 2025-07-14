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
    @State private var showDeleteConfirmation = false
    @State private var showAbout = false

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
                            }

                            Button {
                                exportAllCards()
                            } label: {
                                Label(String(localized: "export"), systemImage: "square.and.arrow.up")
                            }

                            if isSelectionMode {
                                Button {
                                    shareSelectedCards()
                                } label: {
                                    Label(String(localized: "share_selected_cards"), systemImage: "square.and.arrow.up")
                                }

                                Button(role: .destructive) {
                                    showDeleteConfirmation = true
                                } label: {
                                    Label(String(localized: "delete"), systemImage: "trash")
                                }
                            }
                            
                            Button {
                                showAbout = true
                            } label: {
                                Label(String(localized: "showAbout"), systemImage: "info.circle")
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
            allowedContentTypes: [.json, felyroUTType],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let url = try result.get().first else { return }
                importCards(from: url)
            } catch {
                print("❌ Import selhal: \(error)")
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportData.map { ExportedFile(data: $0) },
            contentType: .json,
            defaultFilename: "cards"
        ) { result in
            switch result {
            case .success: print("✅ Export dokončen.")
            case .failure(let error): print("❌ Export selhal: \(error)")
            }
        }
        .alert(
            String.localizedStringWithFormat(
                String(localized: "confirm_delete_cards"),
                selectedCards.count
            ),
            isPresented: $showDeleteConfirmation
        ) {
            Button(role: .destructive) {
                deleteSelectedCards()
            } label: {
                Text(String(localized: "delete"))
            }
            Button(String(localized: "cancel"), role: .cancel) {
                showDeleteConfirmation = false
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
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
            print("❌ Export selhal: \(error)")
        }
    }

    private func deleteSelectedCards() {
        for card in selectedCards {
            context.delete(card)
        }
        selectedCards.removeAll()
        isSelectionMode = false
        showDeleteConfirmation = false
    }

    private func shareSelectedCards() {
        guard !selectedCards.isEmpty else { return }

        do {
            let transferCards = selectedCards.map(TransferCard.init)
            let data = try JSONEncoder().encode(transferCards)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("cards.felyro")
            try data.write(to: tempURL)

            print("✅ Soubor připraven: \(tempURL)")
            SharePresenter.presentShareSheet(with: [tempURL])
        } catch {
            print("❌ Chyba při přípravě sdílení: \(error)")
        }
    }




    @MainActor
    private func importCards(from url: URL) {
        Task {
            do {
                let data = try Data(contentsOf: url)

                if url.pathExtension == "felyro" {
                    let transferCards = try JSONDecoder().decode([TransferCard].self, from: data)
                    for tcard in transferCards {
                        context.insert(tcard.toCard())
                    }
                    try context.save()
                    print("✅ Import .felyro úspěšný.")
                } else {
                    let dtos = try JSONDecoder().decode([CardDTO].self, from: data)
                    let allCards = try context.fetch(FetchDescriptor<Card>())

                    for dto in dtos {
                        let baseName = dto.name.trimmingCharacters(in: .whitespaces)
                        let barcode = dto.barcodeData

                        let similar = allCards.filter { $0.name == baseName || $0.name.hasPrefix(baseName + " ") }

                        if similar.contains(where: { $0.name == baseName && $0.barcodeData == barcode }) {
                            print("⏭️ Přeskočeno – \(baseName) s tímto barcode už existuje.")
                            continue
                        }

                        var finalName = baseName
                        var suffix = 2
                        while similar.contains(where: { $0.name == finalName }) {
                            finalName = "\(baseName) \(suffix)"
                            suffix += 1
                        }

                        let card = Card(
                            name: finalName,
                            note: dto.note,
                            barcodeData: dto.barcodeData,
                            barcodeType: dto.barcodeType,
                            category: dto.category
                        )
                        context.insert(card)
                    }

                    try context.save()
                    print("✅ Import JSON úspěšný.")
                }
            } catch {
                print("❌ Import selhal: \(error.localizedDescription)")
            }
        }
    }
}
