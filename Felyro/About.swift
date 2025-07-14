//
//  About.swift
//  Felyro
//
//  Created by Martin Horáček on 14.07.2025.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("📱 Felyro")
                        .font(.title)
                        .bold()
                    
                    Text(String(localized: "About_Text"))
                    
                    Text("🔗 "+String(localized: "Links"))
                        .font(.headline)

                    Link(String(localized: "GitHub_Link"), destination: URL(string: "https://github.com/martinhocz/Felyro")!)
                    Link(String(localized: "Website_Link"), destination: URL(string: "https://felyro.eu")!)
                    Link(String(localized: "License_Link"), destination: URL(string: "https://github.com/martinhocz/Felyro/blob/main/LICENSE")!)
                    Text(String(localized: "AI_Attribution"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    
                }
                .padding()
            }
            .navigationTitle(String(localized: "About"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
