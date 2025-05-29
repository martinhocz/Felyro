//
//  EditCardView.swift
//  Felyro
//
//  Created by Martin Horáček on 28.05.2025.
//
import SwiftUI
import SwiftData

struct EditCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var card: Card

    @State private var barcodeError: String?
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            Section("Informace o kartě") {
                TextField("Název", text: $card.name)

                TextField("Poznámka", text: Binding(
                    get: { card.note ?? "" },
                    set: { card.note = $0 }
                ))

                Picker("Kategorie", selection: $card.category) {
                    ForEach(CategoryType.allCases.filter { $0 != .all }) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
            }

            Section("Čárový kód") {
                TextField("Kód", text: $card.barcodeData)
                    .onChange(of: card.barcodeData) {
                        validateBarcode()
                    }

                Picker("Typ kódu", selection: $card.barcodeType) {
                    ForEach(BarcodeType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .onChange(of: card.barcodeType) {
                    validateBarcode()
                }

                if let error = barcodeError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                if barcodeError == nil,
                   !card.barcodeData.isEmpty,
                   let image = card.generateBarcodeImage() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
            }

            Section {
                Button("Uložit změny") {
                    validateBarcode()
                    if barcodeError == nil {
                        dismiss()
                    }
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Smazat kartu", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Upravit kartu")
        .onAppear {
            validateBarcode()
        }
        .confirmationDialog("Opravdu chcete smazat tuto kartu?",
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible) {
            Button("Smazat", role: .destructive) {
                context.delete(card)
                NotificationCenter.default.post(name: .cardWasDeleted, object: card.id)
                dismiss()
            }
            Button("Zrušit", role: .cancel) {}
        }
    }

    private func validateBarcode() {
        switch card.barcodeType {
        case .ean13:
            barcodeError = card.barcodeData.count == 13 && card.barcodeData.allSatisfy(\.isNumber)
                ? nil : "EAN-13 musí mít přesně 13 číslic"
        case .ean8:
            barcodeError = card.barcodeData.count == 8 && card.barcodeData.allSatisfy(\.isNumber)
                ? nil : "EAN-8 musí mít přesně 8 číslic"
        case .code128:
            barcodeError = card.barcodeData.count >= 4
                ? nil : "Code128 musí mít alespoň 4 znaky"
        case .qr:
            barcodeError = card.barcodeData.isEmpty ? "QR kód nesmí být prázdný" : nil
        }
    }
}
