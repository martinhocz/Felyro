//
//  DataMigrator.swift
//  Felyro
//
//  Created by Martin Horáček on 01.06.2025.
//

import Foundation
import SwiftData

struct DataMigrator {
    static func migrateInvalidCategories() async {
        do {
            let context = try ModelContext(ModelContainer(for: Card.self))
            let descriptor = FetchDescriptor<Card>()
            var cards = try context.fetch(descriptor)

            var didFix = false

            for card in cards {
                if CategoryType(rawValue: card.category.rawValue) == nil {
                    card.category = .other
                    didFix = true
                }
            }

            if didFix {
                try context.save()
                print("✅ Migrace kategorií: opraveny neplatné hodnoty.")
            } else {
                print("✅ Migrace kategorií: není co opravovat.")
            }
        } catch {
            print("❌ Migrace kategorií selhala: \(error.localizedDescription)")
        }
    }
}
