//
//  ImportCoordinator.swift
//  Felyro
//
//  Created by Martin Horáček on 02.06.2025.
//


import Foundation
import SwiftUI

@MainActor
class ImportCoordinator: ObservableObject {
    @Published var importCards: [TransferCard] = []
    @Published var isShowingImportSheet = false

    func handleIncomingURL(_ url: URL) {
        guard url.pathExtension == "felyro" else { return }

        do {
            let data = try Data(contentsOf: url)
            let cards = try JSONDecoder().decode([TransferCard].self, from: data)
            importCards = cards
            isShowingImportSheet = true
        } catch {
            print("❌ Nepodařilo se načíst .felyro soubor: \(error.localizedDescription)")
        }
    }
}
