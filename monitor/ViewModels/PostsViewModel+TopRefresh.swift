//
//  PostsViewModel+TopRefresh.swift
//  monitor
//
//  Created by AI Assistant for foreground refresh functionality
//

import Foundation
import Combine

extension PostsViewModel {
    
    /// Fetches the top 50 most recent posts and prepends any new ones to the current list
    /// without resetting pagination cursors. Used for foreground refresh.
    func fetchTopAndPrepend() {
        print("🔄 [\(category)] Fetching top posts for foreground refresh...")
        
        // Don't interfere with existing loading operations
        guard !isLoadingMore else {
            print("⏸️ [\(category)] Top refresh skipped - already loading")
            return
        }
        
        // Determine categories for API call (same logic as existing methods)
        let apiCategories: [String]?
        if category == "all" || category == "relevant" {
            apiCategories = nil // No categories filter for "all" and "relevant"
        } else {
            apiCategories = [category]
        }
        
        // Build URL for top 50 most recent posts (no 'before' parameter to get the latest)
        guard let url = buildTopPostsURL(limit: 50, categories: apiCategories) else {
            print("❌ [\(category)] Failed to build URL for top refresh")
            return
        }
        
        print("📡 [\(category)] Fetching top posts from: \(url)")
        
        fetchPostsFromURL(url) { [weak self] fetchedPosts in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.prependNewPosts(fetchedPosts)
                print("✅ [\(self.category)] Top refresh complete: processed \(fetchedPosts.count) posts")
            }
        }
    }
    
    /// Builds URL for fetching top posts (most recent first)
    private func buildTopPostsURL(limit: Int = 50, categories: [String]? = nil) -> URL? {
        var components = URLComponents(string: "https://api.monitor.gaulatti.com/posts")
        var queryItems: [URLQueryItem] = []
        
        // Add limit parameter
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        
        // Add categories parameter if provided
        if let categories = categories, !categories.isEmpty {
            queryItems.append(URLQueryItem(name: "categories", value: categories.joined(separator: ",")))
        }
        
        // Note: No 'before' parameter to get the most recent posts
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    /// Prepends new posts to the current list, avoiding duplicates and maintaining sort order
    private func prependNewPosts(_ fetchedPosts: [Post]) {
        // Filter out posts that already exist (by ID)
        let newPosts = fetchedPosts.filter { newPost in
            !self.posts.contains { existingPost in existingPost.id == newPost.id }
        }
        
        guard !newPosts.isEmpty else {
            print("📝 [\(category)] No new posts to add during top refresh")
            return
        }
        
        print("📝 [\(category)] Adding \(newPosts.count) new posts during top refresh")
        
        // Prepend new posts to the beginning of the current list
        posts.insert(contentsOf: newPosts, at: 0)
        
        // Sort the entire list to ensure proper order by posted_at DESC, with tie-break by id
        posts.sort { post1, post2 in
            if post1.posted_at == post2.posted_at {
                // Tie-break by ID (descending to maintain consistency)
                return post1.id > post2.id
            }
            return post1.posted_at > post2.posted_at
        }
        
        // Note: We intentionally DO NOT update oldestTimestamp or hasMore here
        // to preserve pagination state for loadMore() functionality
        
        print("🎯 [\(category)] Posts sorted and pagination state preserved")
    }
}