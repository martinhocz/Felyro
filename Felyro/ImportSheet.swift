//
//  ImportSheet.swift
//  Felyro
//
//  Created by Martin Horáček on 02.06.2025.
//

import SwiftUI
import SwiftData

struct ImportSheet: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss

    let cards: [TransferCard]

    @State private var selectedIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List(cards, id: \.id, selection: $selectedIDs) { card in
                VStack(alignment: .leading) {
                    Text(card.name)
                        .font(.headline)
                    if let note = card.note {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle(String(localized: "import_cards"))
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: toggleSelection) {
                        Text(selectAllLabel)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "import2")) {
                        importSelectedCards()
                    }
                    .disabled(selectedIDs.isEmpty)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // předvybrání všech
                selectedIDs = Set(cards.map(\.id))
            }
        }
    }

    private var selectAllLabel: String {
        selectedIDs.count < cards.count
            ? String(localized: "select_all")
            : String(localized: "deselect_all")
    }

    private func toggleSelection() {
        if selectedIDs.count < cards.count {
            selectedIDs = Set(cards.map(\.id))
        } else {
            selectedIDs.removeAll()
        }
    }

    private func importSelectedCards() {
        Task {
            do {
                let existingCards = try context.fetch(FetchDescriptor<Card>())

                for card in cards where selectedIDs.contains(card.id) {
                    let baseName = card.name.trimmingCharacters(in: .whitespaces)
                    let barcode = card.barcodeData

                    let similar = existingCards.filter {
                        $0.name == baseName || $0.name.hasPrefix(baseName + " ")
                    }

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

                    let newCard = Card(
                        name: finalName,
                        note: card.note,
                        barcodeData: card.barcodeData,
                        barcodeType: card.barcodeType,
                        category: card.category
                    )
                    context.insert(newCard)
                }

                try context.save()
                dismiss()
            } catch {
                print("❌ Import selhal: \(error.localizedDescription)")
            }
        }
    }
}
