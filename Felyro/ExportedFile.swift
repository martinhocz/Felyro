//
//  ExportedFile.swift
//  Felyro
//
//  Created by Martin Horáček on 28.05.2025.
//


import SwiftUI
import UniformTypeIdentifiers

struct ExportedFile: FileDocument {
    static var readableContentTypes: [UTType] = [.json]
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
