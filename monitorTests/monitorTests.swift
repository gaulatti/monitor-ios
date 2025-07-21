//
//  monitorTests.swift
//  monitorTests
//
//  Created by Javier Godoy Núñez on 6/27/25.
//

import Testing
@testable import monitor
import Foundation

struct monitorTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    

    @Test func testNotificationRelevanceThreshold() async throws {
        // Test that NotificationManager's shouldShowNotification respects relevance threshold
        let notificationManager = NotificationManager.shared
        
        // Set a specific threshold
        notificationManager.relevanceThreshold = 5.0
        
        // Create test posts with different relevance scores

        let lowRelevancePost = Post(
            id: "test1",
            content: "Low relevance post",
            source: "test",
            posted_at: Date(),
            categories: ["test"],
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
            categories: ["test"],
            author: "test",
            relevance: 7,
            authorName: nil,
            authorHandle: nil,
            authorAvatar: nil,
            uri: nil,
            media: nil,
            linkPreview: nil,
            lang: nil
        )
        

        let exactThresholdPost = Post(
            id: "test3",
            content: "Exact threshold post",
            source: "test", 
            posted_at: Date(),
            categories: ["test"],
            author: "test",
            relevance: 5,
            authorName: nil,
            authorHandle: nil,
            authorAvatar: nil,
            uri: nil,
            media: nil,
            linkPreview: nil,
            lang: nil
        )
        
        // Test shouldShowNotification logic
        #expect(!notificationManager.shouldShowNotification(for: lowRelevancePost))
        #expect(notificationManager.shouldShowNotification(for: highRelevancePost))
        #expect(notificationManager.shouldShowNotification(for: exactThresholdPost))
    }
    
    @Test func testRelevanceThresholdPersistence() async throws {
        // Test that relevance threshold is properly stored and retrieved
        let notificationManager = NotificationManager.shared
        
        // Set a threshold
        let testThreshold = 7.0
        notificationManager.relevanceThreshold = testThreshold
        
        // Verify it's stored correctly (as integer)
        let storedValue = UserDefaults.standard.integer(forKey: "notificationRelevanceThreshold")
        #expect(storedValue == Int(testThreshold))
        
        // Verify the property returns the correct value
        #expect(notificationManager.relevanceThreshold == testThreshold)
    }
    
    @Test func testPostRelevanceFiltering() async throws {
        // Test that posts are correctly filtered by relevance
        let posts = [
            Post(id: "1", content: "Low", source: "test", posted_at: Date(), categories: ["test"], author: "test", relevance: 2, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil),
            Post(id: "2", content: "Medium", source: "test", posted_at: Date(), categories: ["test"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil),
            Post(id: "3", content: "High", source: "test", posted_at: Date(), categories: ["test"], author: "test", relevance: 8, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil)
        ]
        
        let threshold = 5.0
        let filteredPosts = posts.filter { Double($0.relevance) >= threshold }
        
        #expect(filteredPosts.count == 2)
        #expect(filteredPosts.allSatisfy { $0.relevance >= Int(threshold) })
    }
}
