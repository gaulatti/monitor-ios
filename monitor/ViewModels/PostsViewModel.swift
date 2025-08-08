import Foundation
import Combine
import SwiftUI

class PostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isConnected: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasMore: Bool = true
    let category: String
    private var oldestTimestamp: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // For relevant category filtering
    var relevanceThreshold: Double = 0.0

    init(category: String) {
        self.category = category
        // Don't fetch initial posts automatically - ContentView handles this
    }
    
    // MARK: - URL Building Helper
    private func buildPostsURL(limit: Int = 50, before: Date? = nil, categories: [String]? = nil) -> URL? {
        var components = URLComponents(string: "https://api.monitor.gaulatti.com/posts")
        var queryItems: [URLQueryItem] = []
        
        // Add limit parameter
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        
        // Add before parameter if provided
        if let before = before {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            queryItems.append(URLQueryItem(name: "before", value: formatter.string(from: before)))
        }
        
        // Add categories parameter if provided
        if let categories = categories, !categories.isEmpty {
            queryItems.append(URLQueryItem(name: "categories", value: categories.joined(separator: ",")))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    // MARK: - Pagination Methods
    func fetchInitial() {
        print("🔄 [\(category)] Fetching initial posts...")
        isLoadingMore = true
        hasMore = true
        oldestTimestamp = nil
        
        // Determine categories for API call
        let apiCategories: [String]?
        if category == "all" || category == "relevant" {
            apiCategories = nil // No categories filter for "all" and "relevant"
        } else {
            apiCategories = [category]
        }
        
        guard let url = buildPostsURL(limit: 50, before: nil, categories: apiCategories) else {
            print("❌ [\(category)] Failed to build URL")
            isLoadingMore = false
            return
        }
        
        print("📡 [\(category)] Fetching from: \(url)")
        
        fetchPostsFromURL(url) { [weak self] fetchedPosts in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.posts = fetchedPosts
                self.updateOldestTimestamp(from: fetchedPosts)
                self.hasMore = fetchedPosts.count == 50
                self.isLoadingMore = false
                
                print("✅ [\(self.category)] Initial fetch complete: \(fetchedPosts.count) posts, hasMore: \(self.hasMore)")
            }
        }
    }
    
    func loadMore() {
        guard !isLoadingMore && hasMore else {
            print("⏸️ [\(category)] Load more skipped - isLoadingMore: \(isLoadingMore), hasMore: \(hasMore)")
            return
        }
        
        print("🔄 [\(category)] Loading more posts...")
        isLoadingMore = true
        
        // Determine categories for API call
        let apiCategories: [String]?
        if category == "all" || category == "relevant" {
            apiCategories = nil // No categories filter for "all" and "relevant"
        } else {
            apiCategories = [category]
        }
        
        guard let url = buildPostsURL(limit: 50, before: oldestTimestamp, categories: apiCategories) else {
            print("❌ [\(category)] Failed to build URL for load more")
            isLoadingMore = false
            return
        }
        
        print("📡 [\(category)] Loading more from: \(url)")
        
        fetchPostsFromURL(url) { [weak self] fetchedPosts in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Filter out duplicates based on ID
                let newPosts = fetchedPosts.filter { newPost in
                    !self.posts.contains { $0.id == newPost.id }
                }
                
                self.posts.append(contentsOf: newPosts)
                self.updateOldestTimestamp(from: fetchedPosts)
                self.hasMore = fetchedPosts.count == 50
                self.isLoadingMore = false
                
                print("✅ [\(self.category)] Load more complete: +\(newPosts.count) new posts, total: \(self.posts.count), hasMore: \(self.hasMore)")
            }
        }
    }
    
    private func updateOldestTimestamp(from posts: [Post]) {
        if let oldest = posts.min(by: { $0.posted_at < $1.posted_at }) {
            oldestTimestamp = oldest.posted_at
            print("🕒 [\(category)] Updated oldest timestamp: \(oldest.posted_at)")
        }
    }
    
    private func fetchPostsFromURL(_ url: URL, completion: @escaping ([Post]) -> Void) {
        let decoder = JSONDecoder()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            if let date = isoFormatter.date(from: dateStr) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateStr)")
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ [\(self.category)] Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingMore = false
                }
                return
            }

            guard let data = data else { 
                print("❌ [\(self.category)] No data received")
                DispatchQueue.main.async {
                    self.isLoadingMore = false
                }
                return 
            }

            do {
                // Try to decode as array first
                if let posts = try? decoder.decode([Post].self, from: data) {
                    let filteredPosts = self.filterPostsForCategory(posts)
                    completion(filteredPosts)
                } else if let wrapper = try? decoder.decode(PostListWrapper.self, from: data) {
                    let filteredPosts = self.filterPostsForCategory(wrapper.data)
                    completion(filteredPosts)
                } else {
                    print("❌ [\(self.category)] Failed to decode posts")
                    DispatchQueue.main.async {
                        self.isLoadingMore = false
                    }
                }
            }
        }.resume()
    }
    
    private func filterPostsForCategory(_ posts: [Post]) -> [Post] {
        if category == "all" {
            return posts
        } else if category == "relevant" {
            // Filter by relevance threshold
            return posts.filter { Double($0.relevance) >= relevanceThreshold }
        } else {
            return posts.filter { $0.categories.contains(category) }
        }
    }

    // MARK: - Legacy Methods (for compatibility)
    private func fetchInitialPosts() {
        fetchInitial()
    }
    
    private func processFetchedPosts(_ fetchedPosts: [Post]) {
        // This method is kept for compatibility but the new pagination methods handle this
        posts = filterPostsForCategory(fetchedPosts)
        updateOldestTimestamp(from: posts)
        hasMore = fetchedPosts.count >= 50
    }
    
    func insertPost(_ post: Post) {
        // Check if post already exists
        guard !posts.contains(where: { $0.id == post.id }) else { 
            print("Post with ID \(post.id) already exists, skipping insertion")
            return 
        }
        
        // Debug: Log SSE post structure
        print("SSE Post insertion - ID: \(post.id)")
        print("URI: \(post.uri ?? "nil")")
        print("Media count: \(post.media?.count ?? 0)")
        print("Categories: \(post.categories)")
        
        // For "all" category, accept all posts. For specific categories, check if post matches category
        let shouldInsert = category == "all" || post.categories.contains(category)
        guard shouldInsert else { 
            print("Post \(post.id) does not match category \(category), skipping")
            return 
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            posts.insert(post, at: 0)
            // Keep only the most recent posts (more for "all", less for specific categories)
            let maxPosts = category == "all" ? 1000 : 500
            if posts.count > maxPosts {
                posts.removeLast()
            }
        }
    }
}

// Helper for decoding { data: [Post] }
private struct PostListWrapper: Decodable {
    let data: [Post]
}
