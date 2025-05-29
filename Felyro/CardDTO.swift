//
//  CardDTO.swift
//  Felyro
//
//  Created by Martin Horáček on 28.05.2025.
//


import Foundation

struct CardDTO: Codable, Identifiable {
    var id = UUID()
    var name: String
    var note: String?
    var barcodeData: String
    var barcodeType: BarcodeType
    var category: CategoryType

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        barcodeData = try container.decode(String.self, forKey: .barcodeData)
        barcodeType = try container.decode(BarcodeType.self, forKey: .barcodeType)
        category = try container.decodeIfPresent(CategoryType.self, forKey: .category) ?? .other
    }


    func toCard() -> Card {
        Card(name: name, note: note, barcodeData: barcodeData, barcodeType: barcodeType, category: category)
    }
}
