//
//  SharePresenter.swift
//  Felyro
//
//  Created by Martin Horáček on 03.06.2025.
//


import UIKit

enum SharePresenter {
    static func presentShareSheet(with items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.modalPresentationStyle = .automatic

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
