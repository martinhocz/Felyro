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
            Section(String(localized: "info_about_card")) {
                TextField(String(localized: "name"), text: $card.name)

                TextField(String(localized: "note"), text: Binding(
                    get: { card.note ?? "" },
                    set: { card.note = $0 }
                ))

                Picker(String(localized: "category"), selection: $card.category) {
                    ForEach(CategoryType.allCases.filter { $0 != .all }) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
            }

            Section(String(localized: "barcode")) {
                TextField(String(localized: "code"), text: $card.barcodeData)
                    .onChange(of: card.barcodeData) {
                        validateBarcode()
                    }

                Picker(String(localized: "type_code"), selection: $card.barcodeType) {
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
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(String(localized: "remove_card"), systemImage: "trash")
                }
            }
        }
        .navigationTitle(String(localized: "edit_card"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(String(localized: "save_changes")) {
                    dismiss()
                }
                .disabled(barcodeError != nil)
            }
        }
        .onAppear {
            validateBarcode()
        }
        .confirmationDialog(String(localized: "sure_delete"),
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible) {
            Button(String(localized: "delete"), role: .destructive) {
                context.delete(card)
                NotificationCenter.default.post(name: .cardWasDeleted, object: card.id)
                dismiss()
            }
            Button(String(localized: "cancel"), role: .cancel) {}
        }
    }

    private func validateBarcode() {
        switch card.barcodeType {
        case .ean13:
            barcodeError = card.barcodeData.count == 13 && card.barcodeData.allSatisfy(\.isNumber)
                ? nil : String(localized: "ean-13_error")
        case .ean8:
            barcodeError = card.barcodeData.count == 8 && card.barcodeData.allSatisfy(\.isNumber)
                ? nil : String(localized: "ean-8_error")
        case .code128:
            barcodeError = card.barcodeData.count >= 4
                ? nil : String(localized: "code128_error")
        case .qr:
            barcodeError = card.barcodeData.isEmpty
                ? String(localized: "qr_error") : nil
        }
    }
}
