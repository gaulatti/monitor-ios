import Foundation
import Combine
import SwiftUI

class PostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isConnected: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasMore: Bool = true
    @Published var errorMessage: String? = nil // NEW: capture per-category errors

    let category: String
    private var oldestTimestamp: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // For relevant category filtering
    var relevanceThreshold: Double = 0.0

    init(category: String) {
        self.category = category
        // ContentView triggers fetchInitial()
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
        errorMessage = nil

        let apiCategories: [String]?
        if category == "all" || category == "relevant" {
            apiCategories = nil
        } else {
            apiCategories = [category]
        }

        guard let url = buildPostsURL(limit: 50, before: nil, categories: apiCategories) else {
            print("❌ [\(category)] Failed to build URL")
            isLoadingMore = false
            errorMessage = "Failed to build URL"
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
                if fetchedPosts.isEmpty {
                    if self.errorMessage == nil {
                        print("ℹ️ [\(self.category)] Initial fetch returned 0 posts (no errorMessage set)")
                    }
                } else {
                    print("✅ [\(self.category)] Initial fetch complete: \(fetchedPosts.count) posts, hasMore: \(self.hasMore)")
                }
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

        let apiCategories: [String]?
        if category == "all" || category == "relevant" {
            apiCategories = nil
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
                let newPosts = fetchedPosts.filter { newPost in
                    !self.posts.contains { $0.id == newPost.id }
                }

                self.posts.append(contentsOf: newPosts)

                if !fetchedPosts.isEmpty {
                    self.updateOldestTimestamp(from: fetchedPosts)
                }

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
    
    // MARK: - Networking / Decoding
    private struct PostListWrapper: Decodable { let data: [Post] } // existing style
    private struct PostsWrapper: Decodable { let posts: [Post] }
    private struct NestedDataPostsWrapper: Decodable { let data: Inner; struct Inner: Decodable { let posts: [Post] } }

    internal func fetchPostsFromURL(_ url: URL, completion: @escaping ([Post]) -> Void) {
        let decoder = JSONDecoder()
        let isoFormatter = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(value)")
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ [\(self.category)] Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingMore = false
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                print("❌ [\(self.category)] No data received")
                DispatchQueue.main.async {
                    self.isLoadingMore = false
                    self.errorMessage = "No data received"
                }
                return
            }

            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status >= 400 {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
                print("❌ [\(self.category)] HTTP \(status). Body:\n\(bodyString)")
                DispatchQueue.main.async {
                    self.isLoadingMore = false
                    self.errorMessage = "HTTP \(status)"
                }
                return
            }

            // Attempt multiple envelope shapes
            var decodedPosts: [Post]? = nil
            if let posts = try? decoder.decode([Post].self, from: data) {
                decodedPosts = posts
            } else if let wrapper = try? decoder.decode(PostListWrapper.self, from: data) {
                decodedPosts = wrapper.data
            } else if let postsWrapper = try? decoder.decode(PostsWrapper.self, from: data) {
                decodedPosts = postsWrapper.posts
            } else if let nested = try? decoder.decode(NestedDataPostsWrapper.self, from: data) {
                decodedPosts = nested.data.posts
            }

            if let posts = decodedPosts {
                let filtered = self.filterPostsForCategory(posts)
                completion(filtered)
            } else {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
                print("❌ [\(self.category)] Failed to decode posts. Raw body:\n\(bodyString)")
                DispatchQueue.main.async {
                    self.isLoadingMore = false
                    self.errorMessage = "Decode failure"
                }
            }
        }.resume()
    }
    
    // MARK: - Relevance Threshold Management
    func updateRelevanceThreshold(_ newThreshold: Double) {
        guard category == "relevant" else { return }
        let oldThreshold = relevanceThreshold
        relevanceThreshold = newThreshold
        print("🎯 [\(category)] Updating relevance threshold from \(oldThreshold) to \(newThreshold)")
        fetchInitial()
    }
    
    internal func filterPostsForCategory(_ posts: [Post]) -> [Post] {
        if category == "all" {
            return posts
        } else if category == "relevant" {
            return posts.filter { Double($0.relevance) >= relevanceThreshold }
        } else {
            return posts.filter { post in
                post.categories.contains { $0.caseInsensitiveCompare(category) == .orderedSame }
            }
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
        guard !posts.contains(where: { $0.id == post.id }) else {
            print("Post with ID \(post.id) already exists, skipping insertion")
            return
        }
        print("SSE Post insertion - ID: \(post.id)")
        print("URI: \(post.uri ?? "nil")")
        print("Media count: \(post.media?.count ?? 0)")
        print("Categories: \(post.categories)")

        let shouldInsert: Bool
        if category == "all" {
            shouldInsert = true
        } else if category == "relevant" {
            shouldInsert = Double(post.relevance) >= relevanceThreshold
        } else {
            shouldInsert = post.categories.contains { $0.caseInsensitiveCompare(category) == .orderedSame }
        }

        guard shouldInsert else {
            print("Post \(post.id) does not match category \(category), skipping")
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            posts.insert(post, at: 0)
            let maxPosts = category == "all" ? 1000 : 500
            if posts.count > maxPosts { posts.removeLast() }
        }
    }
}
