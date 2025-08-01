//
//  NavigationManager.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/18/25.
//

import SwiftUI
import Combine

class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var selectedPost: Post? = nil
    @Published var showPostDetail = false
    @Published var deepLinkPostId: String? = nil
    
    private init() {}
    
    // Navigate to a specific post
    func navigateToPost(_ post: Post) {
        print("🔍 NavigationManager: Navigating to post \(post.id)")
        selectedPost = post
        showPostDetail = true
        
        // Mark post as read when user views it
        NotificationManager.shared.markPostAsRead(post.id)
        
        // Send analytics about post view
        NotificationManager.shared.sendAnalytics(event: "post_viewed", data: [
            "postId": post.id,
            "source": "tap",
            "relevance": post.relevance
        ])
    }
    
    // Handle deep link from notification
    func handleDeepLink(postId: String) {
        print("🔗 NavigationManager: Handling deep link for post \(postId)")
        deepLinkPostId = postId
        
        // Mark post as read immediately
        NotificationManager.shared.markPostAsRead(postId)
        
        // Send analytics about deep link
        NotificationManager.shared.sendAnalytics(event: "post_viewed", data: [
            "postId": postId,
            "source": "notification_deep_link"
        ])
    }
    
    // Close post detail view
    func dismissPostDetail() {
        print("❌ NavigationManager: Dismissing post detail")
        selectedPost = nil
        showPostDetail = false
        deepLinkPostId = nil
    }
}
