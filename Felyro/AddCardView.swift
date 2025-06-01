//
//  AddCardView.swift
//  Felyro
//
//  Created by Martin Horáček on 28.05.2025.
//

import SwiftUI
import SwiftData

struct AddCardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var note = ""
    @State private var barcodeData = ""
    @State private var barcodeType: BarcodeType = .code128
    @State private var category: CategoryType = .other
    @State private var barcodeError: String?
    @State private var showingScanner = false

    var body: some View {
        Form {
            Section(String(localized: "info_about_card")) {
                TextField(String(localized: "name"), text: $name)
                TextField(String(localized: "note"), text: $note)

                Picker(String(localized: "category"), selection: $category) {
                    ForEach(CategoryType.allCases.filter { $0 != .all }) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
            }

            Section(String(localized: "barcode")) {
                TextField(String(localized: "code"), text: $barcodeData)
                    .onChange(of: barcodeData) {
                        validateBarcode()
                    }

                Picker(String(localized: "type_code"), selection: $barcodeType) {
                    ForEach(BarcodeType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .onChange(of: barcodeType) {
                    validateBarcode()
                }

                Button(String(localized: "scan")) {
                    showingScanner = true
                }

                if let error = barcodeError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                if barcodeError == nil,
                   !barcodeData.isEmpty {
                    let tempCard = Card(name: "", barcodeData: barcodeData, barcodeType: barcodeType, category: category)
                    if let image = tempCard.generateBarcodeImage() {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "add_card"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(String(localized: "cancel")) {
                    dismiss()
                }
                .foregroundColor(.red)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(String(localized: "save")) {
                    validateBarcode()
                    if barcodeError == nil {
                        let newCard = Card(name: name, note: note, barcodeData: barcodeData, barcodeType: barcodeType, category: category)
                        context.insert(newCard)
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingScanner) {
            BarcodeScannerView { code in
                barcodeData = code
                showingScanner = false
            }
        }

        .onAppear {
            validateBarcode()
        }
    }

    private func validateBarcode() {
        switch barcodeType {
        case .ean13:
            barcodeError = barcodeData.count == 13 && barcodeData.allSatisfy(\.isNumber)
                ? nil : String(localized: "ean-13_error")
        case .ean8:
            barcodeError = barcodeData.count == 8 && barcodeData.allSatisfy(\.isNumber)
                ? nil : String(localized: "ean-8_error")
        case .code128:
            barcodeError = barcodeData.count >= 4
                ? nil : String(localized: "code128_error")
        case .qr:
            barcodeError = barcodeData.isEmpty ? String(localized: "qr_error") : nil
        }
    }
}
