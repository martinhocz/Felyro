//
//  CardDetailView.swift
//  Felyro
//
//  Created by Martin Horáček on 28.05.2025.
//
import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct CardDetailView: View {
    @Bindable var card: Card
    @Environment(\.dismiss) private var dismiss
    @State private var previousBrightness: CGFloat?
    @State private var wasDeleted = false


    var body: some View {
        VStack(spacing: 20) {
            if let image = card.generateBarcodeImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)

                Text(card.barcodeData)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            } else {
                Text(String(localized: "error_with_generating_code"))
                    .foregroundColor(.secondary)
            }

            if let note = card.note, !note.isEmpty {
                Text(note)
                    .padding()
            }

            Spacer()
        }
        .navigationTitle(card.name)
        .toolbar {
            NavigationLink(String(localized: "edit"), destination: EditCardView(card: card))
        }
        .padding()
        .onAppear {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        }
        .onDisappear {
            if let previous = previousBrightness {
                UIScreen.main.brightness = previous
            }
        }
        .onChange(of: card.name) {
            if card.name.isEmpty {
                dismiss()
            }
        }
        .onChange(of: wasDeleted) {
            if wasDeleted {
                dismiss()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cardWasDeleted)) { notification in
            if let deletedId = notification.object as? Card.ID, deletedId == card.id {
                wasDeleted = true
            }
        }

    }
}

extension Notification.Name {
    static let cardWasDeleted = Notification.Name("cardWasDeleted")
}
