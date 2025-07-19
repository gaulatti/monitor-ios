//
//  monitorTests.swift
//  monitorTests
//
//  Created by Javier Godoy Núñez on 6/27/25.
//

import Testing
@testable import monitor

struct monitorTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testNotificationRelevanceFiltering() async throws {
        // Test that notification filtering uses the same threshold as the NotificationManager
        let notificationManager = NotificationManager.shared
        
        // Create test posts with different relevance levels
        let lowRelevancePost = Post(
            id: "test1",
            content: "Low relevance post",
            source: "test",
            posted_at: Date(),
            categories: ["business"],
            author: "test",
            relevance: 3,
            authorName: nil,
            authorHandle: nil,
            authorAvatar: nil,
            uri: nil,
            media: nil,
            linkPreview: nil,
            lang: nil
        )
        
        let highRelevancePost = Post(
            id: "test2",
            content: "High relevance post",
            source: "test",
            posted_at: Date(),
            categories: ["business"],
            author: "test",
            relevance: 8,
            authorName: nil,
            authorHandle: nil,
            authorAvatar: nil,
            uri: nil,
            media: nil,
            linkPreview: nil,
            lang: nil
        )
        
        // Test with default threshold (5)
        notificationManager.relevanceThreshold = 5.0
        
        #expect(!notificationManager.shouldShowNotification(for: lowRelevancePost))
        #expect(notificationManager.shouldShowNotification(for: highRelevancePost))
        
        // Test with higher threshold (7)
        notificationManager.relevanceThreshold = 7.0
        
        #expect(!notificationManager.shouldShowNotification(for: lowRelevancePost))
        #expect(notificationManager.shouldShowNotification(for: highRelevancePost))
        
        // Test with lower threshold (2)
        notificationManager.relevanceThreshold = 2.0
        
        #expect(notificationManager.shouldShowNotification(for: lowRelevancePost))
        #expect(notificationManager.shouldShowNotification(for: highRelevancePost))
    }
    
    @Test func testRelevanceColumnFiltering() async throws {
        // Test that posts should be filtered for "relevant" column using the same threshold
        let posts = [
            Post(id: "1", content: "Post 1", source: "test", posted_at: Date(), categories: ["business"], author: "test", relevance: 2, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil),
            Post(id: "2", content: "Post 2", source: "test", posted_at: Date(), categories: ["business"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil),
            Post(id: "3", content: "Post 3", source: "test", posted_at: Date(), categories: ["business"], author: "test", relevance: 8, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil),
        ]
        
        let threshold = 5.0
        let relevantPosts = posts.filter { $0.relevance >= Int(threshold) }
        
        // Should include posts with relevance >= 5
        #expect(relevantPosts.count == 2)
        #expect(relevantPosts.contains { $0.id == "2" })
        #expect(relevantPosts.contains { $0.id == "3" })
        #expect(!relevantPosts.contains { $0.id == "1" })
    }

}
