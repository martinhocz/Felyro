//
//  SplashView.swift
//  Felyro
//
//  Created by Martin Horáček on 29.05.2025.
//


import SwiftUI

struct SplashView: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            CardGridView()
        } else {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                //Image("LaunchLogo3")
                  //  .resizable()
                    //.scaledToFit()
                    //.frame(width: 150, height: 150)
                GeometryReader { geometry in
                    Image("LaunchLogo3")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }

            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}
