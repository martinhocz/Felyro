//
//  DataMigrator.swift
//  Felyro
//
//  Created by Martin Horáček on 01.06.2025.
//
import Foundation
import SwiftData

struct DataMigrator {
    static func migrateInvalidCategories() {
        do {
            let container = try ModelContainer(for: Card.self)
            let context = ModelContext(container)
            let cards = try context.fetch(FetchDescriptor<Card>())

            var didFix = false

            for card in cards {
                if CategoryType(rawValue: card.category.rawValue) == nil {
                    card.category = .other
                    didFix = true
                }
            }

            if didFix {
                try context.save()
                print("✅ Migrace proběhla")
            } else {
                print("ℹ️ Není co opravovat")
            }
        } catch {
            print("❌ Migrace selhala: \(error.localizedDescription)")
        }
    }
}
