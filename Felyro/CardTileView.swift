//
//  CardTileView.swift
//  Felyro
//
//  Created by Martin Horáček on 28.05.2025.
//

import SwiftUI

struct CardTileView: View {
    let card: Card
    var isSelected: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Spacer()
                Text(card.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .padding(6)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}
