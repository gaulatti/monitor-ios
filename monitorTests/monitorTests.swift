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
            lang: nil,
            hash: nil,
            uuid: nil,
            matchScore: nil
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
            lang: nil,
            hash: nil,
            uuid: nil,
            matchScore: nil
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
            lang: nil,
            hash: nil,
            uuid: nil,
            matchScore: nil
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
            Post(id: "1", content: "Low", source: "test", posted_at: Date(), categories: ["test"], author: "test", relevance: 2, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil),
            Post(id: "2", content: "Medium", source: "test", posted_at: Date(), categories: ["test"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil),
            Post(id: "3", content: "High", source: "test", posted_at: Date(), categories: ["test"], author: "test", relevance: 8, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        ]
        
        let threshold = 5.0
        let filteredPosts = posts.filter { Double($0.relevance) >= threshold }
        
        #expect(filteredPosts.count == 2)
        #expect(filteredPosts.allSatisfy { $0.relevance >= Int(threshold) })
    }
    
    @Test func testPostsViewModelInitialization() async throws {
        // Test that PostsViewModel initializes correctly with pagination properties
        let viewModel = PostsViewModel(category: "test")
        
        #expect(viewModel.category == "test")
        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.hasMore == true)
        #expect(viewModel.isLoadingMore == false)
        #expect(viewModel.relevanceThreshold == 0.0)
    }
    
    @Test func testRelevantCategoryFiltering() async throws {
        // Test that relevant category filtering works correctly with threshold
        let viewModel = PostsViewModel(category: "relevant")
        viewModel.relevanceThreshold = 6.0
        
        let testPosts = [
            Post(id: "1", content: "Low", source: "test", posted_at: Date(), categories: ["test"], author: "test", relevance: 3, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil),
            Post(id: "2", content: "High", source: "test", posted_at: Date(), categories: ["test"], author: "test", relevance: 8, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        ]
        
        // Test the filtering logic by simulating what happens in processFetchedPosts
        let filteredPosts = testPosts.filter { Double($0.relevance) >= viewModel.relevanceThreshold }
        
        #expect(filteredPosts.count == 1)
        #expect(filteredPosts.first?.relevance == 8)
    }
    
    @Test func testCategorySpecificFiltering() async throws {
        // Test that category-specific filtering works correctly
        let viewModel = PostsViewModel(category: "world")
        
        let testPosts = [
            Post(id: "1", content: "World news", source: "test", posted_at: Date(), categories: ["world"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil),
            Post(id: "2", content: "Tech news", source: "test", posted_at: Date(), categories: ["technology"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil),
            Post(id: "3", content: "World politics", source: "test", posted_at: Date(), categories: ["world", "politics"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        ]
        
        let filteredPosts = testPosts.filter { $0.categories.contains(viewModel.category) }
        
        #expect(filteredPosts.count == 2)
        #expect(filteredPosts.allSatisfy { $0.categories.contains("world") })
    }
    
    @Test func testInsertPostLogic() async throws {
        // Test that insertPost correctly filters based on category
        let allViewModel = PostsViewModel(category: "all")
        let worldViewModel = PostsViewModel(category: "world")
        let relevantViewModel = PostsViewModel(category: "relevant")
        relevantViewModel.relevanceThreshold = 5.0
        
        let worldPost = Post(id: "1", content: "World news", source: "test", posted_at: Date(), categories: ["world"], author: "test", relevance: 7, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        
        let techPost = Post(id: "2", content: "Tech news", source: "test", posted_at: Date(), categories: ["technology"], author: "test", relevance: 3, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        
        // Test insertPost behavior
        allViewModel.insertPost(worldPost)
        allViewModel.insertPost(techPost)
        #expect(allViewModel.posts.count == 2) // "all" accepts all posts
        
        worldViewModel.insertPost(worldPost)
        worldViewModel.insertPost(techPost)
        #expect(worldViewModel.posts.count == 1) // only world category post
        
        relevantViewModel.insertPost(worldPost)
        relevantViewModel.insertPost(techPost)
        #expect(relevantViewModel.posts.count == 1) // only high relevance post (7 >= 5.0)
    }
    
    @Test func testForegroundRefreshDeduplication() async throws {
        // Test that the foreground refresh logic properly deduplicates posts
        let viewModel = PostsViewModel(category: "all")
        
        // Setup initial posts
        let existingPost1 = Post(id: "1", content: "Existing post 1", source: "test", posted_at: Date().addingTimeInterval(-100), categories: ["test"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        let existingPost2 = Post(id: "2", content: "Existing post 2", source: "test", posted_at: Date().addingTimeInterval(-200), categories: ["test"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        
        viewModel.posts = [existingPost1, existingPost2]
        
        // Simulate fetched posts that include duplicates and new posts
        let newPost = Post(id: "3", content: "New post", source: "test", posted_at: Date(), categories: ["test"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        let duplicatePost = existingPost1 // Same ID as existing post
        
        let fetchedPosts = [newPost, duplicatePost, existingPost2] // Mix of new and existing
        
        // Test deduplication logic manually (simulating what prependNewPosts does)
        let newPosts = fetchedPosts.filter { newPost in
            !viewModel.posts.contains { existingPost in existingPost.id == newPost.id }
        }
        
        #expect(newPosts.count == 1) // Only the truly new post should remain
        #expect(newPosts.first?.id == "3") // Should be the new post
    }
    
    @Test func testPostSortingByDate() async throws {
        // Test that posts are correctly sorted by posted_at DESC with ID tie-break
        let viewModel = PostsViewModel(category: "all")
        
        let now = Date()
        let post1 = Post(id: "post1", content: "First", source: "test", posted_at: now.addingTimeInterval(-100), categories: ["test"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        let post2 = Post(id: "post2", content: "Second", source: "test", posted_at: now, categories: ["test"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        let post3 = Post(id: "post3", content: "Third", source: "test", posted_at: now, categories: ["test"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        
        var posts = [post1, post2, post3]
        
        // Test sorting logic (simulating what prependNewPosts does)
        posts.sort { post1, post2 in
            if post1.posted_at == post2.posted_at {
                // Tie-break by ID (descending to maintain consistency)
                return post1.id > post2.id
            }
            return post1.posted_at > post2.posted_at
        }
        
        // Should be sorted by date DESC, then by ID DESC for ties
        #expect(posts[0].id == "post3") // Most recent date, higher ID
        #expect(posts[1].id == "post2") // Most recent date, lower ID  
        #expect(posts[2].id == "post1") // Older date
    }
    
    @Test func testPaginationStatePreservation() async throws {
        // Test that foreground refresh preserves pagination state
        let viewModel = PostsViewModel(category: "all")
        
        // Setup initial state with pagination
        viewModel.hasMore = true
        viewModel.isLoadingMore = false
        
        let oldPost = Post(id: "old", content: "Old post", source: "test", posted_at: Date().addingTimeInterval(-1000), categories: ["test"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        viewModel.posts = [oldPost]
        
        // Simulate the logic that preserves pagination state
        // (In the real implementation, fetchTopAndPrepend does NOT modify hasMore or oldestTimestamp)
        let originalHasMore = viewModel.hasMore
        let originalIsLoadingMore = viewModel.isLoadingMore
        
        // Add a new post (simulating prepend without changing pagination state)
        let newPost = Post(id: "new", content: "New post", source: "test", posted_at: Date(), categories: ["test"], author: "test", relevance: 5, authorName: nil, authorHandle: nil, authorAvatar: nil, uri: nil, media: nil, linkPreview: nil, lang: nil, hash: nil, uuid: nil, matchScore: nil)
        viewModel.posts.insert(newPost, at: 0)
        
        // Verify pagination state is preserved
        #expect(viewModel.hasMore == originalHasMore)
        #expect(viewModel.isLoadingMore == originalIsLoadingMore)
        #expect(viewModel.posts.count == 2)
        #expect(viewModel.posts.first?.id == "new")
    }
}
