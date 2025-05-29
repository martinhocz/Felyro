//
//  Card.swift
//  Felyro
//
//  Created by Martin Horáček on 28.05.2025.
//
import Foundation
import SwiftData
import UIKit
import CoreImage.CIFilterBuiltins

enum BarcodeType: String, Codable, CaseIterable, Identifiable {
    case code128, ean13, ean8, qr

    var id: String { self.rawValue }
    var displayName: String {
        switch self {
        case .code128: return "Code 128"
        case .ean13: return "EAN-13"
        case .ean8: return "EAN-8"
        case .qr: return "QR"
        }
    }
}

enum CategoryType: String, Codable, CaseIterable, Identifiable {
    case all = "Všechny"
    case groceries = "Potraviny"
    case drugstore = "Drogerie"
    case fashion = "Móda"
    case electronics = "Elektronika"
    case other = "Ostatní"

    var id: String { self.rawValue }
    var displayName: String { self.rawValue }
}

@Model
final class Card {
    var name: String
    var note: String?
    var barcodeData: String
    var barcodeType: BarcodeType
    var category: CategoryType

    init(name: String, note: String? = nil, barcodeData: String, barcodeType: BarcodeType = .code128, category: CategoryType = .other) {
        self.name = name
        self.note = note
        self.barcodeData = barcodeData
        self.barcodeType = barcodeType
        self.category = category
    }

    func generateBarcodeImage() -> UIImage? {
        let context = CIContext()
        let data = Data(barcodeData.utf8)
        let filter: CIFilter?

        switch barcodeType {
        case .code128:
            let f = CIFilter.code128BarcodeGenerator()
            f.setValue(data, forKey: "inputMessage")
            filter = f
        case .qr:
            let f = CIFilter.qrCodeGenerator()
            f.setValue(data, forKey: "inputMessage")
            filter = f
        case .ean13:
            let f = CIFilter(name: "CICode128BarcodeGenerator")
            f?.setValue(data, forKey: "inputMessage")
            filter = f
        case .ean8:
            return nil
        }

        guard let output = filter?.outputImage else { return nil }
        let scaled = output.transformed(by: .init(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}
