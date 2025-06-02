//
//  FelyroApp.swift
//  Felyro
//
//  Created by Martin Horáček on 28.05.2025.
//

import SwiftUI
import SwiftData

@main
struct FelyroApp: App {
    @StateObject private var importCoordinator = ImportCoordinator()

    init() {
        DataMigrator.migrateInvalidCategories()
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(importCoordinator)
                .onOpenURL { url in
                    importCoordinator.handleIncomingURL(url)
                }
                .sheet(isPresented: $importCoordinator.isShowingImportSheet) {
                    ImportSheet(cards: importCoordinator.importCards)
                }
                .modelContainer(for: Card.self)
        }
    }
}
