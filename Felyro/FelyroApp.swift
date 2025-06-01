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
    init() {
        DataMigrator.migrateInvalidCategories()
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .modelContainer(for: Card.self)
        }
    }
}
