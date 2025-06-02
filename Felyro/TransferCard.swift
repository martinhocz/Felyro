//
//  TransferCard.swift
//  Felyro
//
//  Created by Martin Horáček on 02.06.2025.
//


import SwiftUI
import UniformTypeIdentifiers

let felyroUTType = UTType(exportedAs: "martinho.cz.Felyro.cardbundle")

struct TransferCard: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var note: String?
    var barcodeData: String
    var barcodeType: BarcodeType
    var category: CategoryType

    init(from card: Card) {
        self.name = card.name
        self.note = card.note
        self.barcodeData = card.barcodeData
        self.barcodeType = card.barcodeType
        self.category = card.category
    }

    func toCard() -> Card {
        Card(name: name, note: note, barcodeData: barcodeData, barcodeType: barcodeType, category: category)
    }
}

struct CardExportDocument: FileDocument {
    static var readableContentTypes: [UTType] = [felyroUTType]
    var cards: [TransferCard]

    init(cards: [TransferCard]) {
        self.cards = cards
    }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        self.cards = try JSONDecoder().decode([TransferCard].self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(cards)
        return .init(regularFileWithContents: data)
    }
}
