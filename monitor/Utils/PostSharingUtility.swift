//
//  PostSharingUtility.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/2/25.
//
import SwiftUI

struct PostSharingUtility {
    static func sharePost(_ post: Post) {
        let message = "📰 \(post.content)"

        let activityViewController = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )

        // Get topmost view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("Could not find root view controller")
            return
        }

        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }

        topViewController.present(activityViewController, animated: true)
    }
}
