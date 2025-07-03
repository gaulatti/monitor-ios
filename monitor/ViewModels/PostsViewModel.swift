import Foundation
import Combine
import SwiftUI

class PostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isConnected: Bool = false
    let category: String
    private var cancellables = Set<AnyCancellable>()

    init(category: String) {
        self.category = category
        // Don't fetch initial posts automatically - ContentView handles this
    }

    private func fetchInitialPosts() {
        guard let url = URL(string: "https://api.monitor.gaulatti.com/posts") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data else { return }
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
            // Try to decode as array first
            if let posts = try? decoder.decode([Post].self, from: data) {
                DispatchQueue.main.async {
                    if self?.category == "all" {
                        // For "all" category, include all posts
                        self?.posts = Array(posts.prefix(50))
                    } else {
                        // For specific categories, filter by category
                        self?.posts = posts.filter { $0.categories.contains(self?.category ?? "") }
                    }
                }
            } else if let wrapper = try? decoder.decode(PostListWrapper.self, from: data) {
                DispatchQueue.main.async {
                    if self?.category == "all" {
                        // For "all" category, include all posts
                        self?.posts = Array(wrapper.data.prefix(50))
                    } else {
                        // For specific categories, filter by category
                        self?.posts = wrapper.data.filter { $0.categories.contains(self?.category ?? "") }
                    }
                }
            } else {
                print("Failed to decode posts: \(String(data: data, encoding: .utf8) ?? "<no data>")")
            }
        }.resume()
    }
    
    func insertPost(_ post: Post) {
        // Check if post already exists
        guard !posts.contains(where: { $0.id == post.id }) else { return }
        
        // For "all" category, accept all posts. For specific categories, check if post matches category
        let shouldInsert = category == "all" || post.categories.contains(category)
        guard shouldInsert else { return }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            posts.insert(post, at: 0)
            // Keep only the most recent posts (more for "all", less for specific categories)
            let maxPosts = category == "all" ? 50 : 30
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
