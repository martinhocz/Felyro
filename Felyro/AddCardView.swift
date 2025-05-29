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
            Section("Informace o kartě") {
                TextField("Název", text: $name)
                TextField("Poznámka", text: $note)

                Picker("Kategorie", selection: $category) {
                    ForEach(CategoryType.allCases.filter { $0 != .all }) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
            }

            Section("Čárový kód") {
                TextField("Kód", text: $barcodeData)
                    .onChange(of: barcodeData) {
                        validateBarcode()
                    }

                Picker("Typ kódu", selection: $barcodeType) {
                    ForEach(BarcodeType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .onChange(of: barcodeType) {
                    validateBarcode()
                }

                Button("Skenovat") {
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
        .navigationTitle("Přidat kartu")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Zrušit") {
                    dismiss()
                }
                .foregroundColor(.red)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Uložit") {
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
                ? nil : "EAN-13 musí mít přesně 13 číslic"
        case .ean8:
            barcodeError = barcodeData.count == 8 && barcodeData.allSatisfy(\.isNumber)
                ? nil : "EAN-8 musí mít přesně 8 číslic"
        case .code128:
            barcodeError = barcodeData.count >= 4
                ? nil : "Code128 musí mít alespoň 4 znaky"
        case .qr:
            barcodeError = barcodeData.isEmpty ? "QR kód nesmí být prázdný" : nil
        }
    }
}
