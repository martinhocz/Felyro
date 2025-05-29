//
//  FelyroApp.swift
//  Felyro
//
//  Created by Martin Horáček on 28.05.2025.
//

import SwiftUI

@main
struct FelyroApp: App {
    var body: some Scene {
            WindowGroup {
                //CardGridView()
                  //  .modelContainer(for: Card.self)
                SplashView()
                    .modelContainer(for: Card.self)
            }
        }
}
