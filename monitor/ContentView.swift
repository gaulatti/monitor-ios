//
//  ContentView.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 6/27/25.
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    // Categories for columns with accent colors
    private let categories = ["all", "relevant", "business", "world", "politics", "technology", "weather"]
    private let categoryColors: [String: Color] = [
        "all": Color(red: 0.75, green: 0.75, blue: 0.75), // #c0c0c0 - neutral gray for all
        "relevant": Color(red: 0.85, green: 0.35, blue: 0.35), // #d95959 - red for relevant/important
        "business": Color(red: 0.06, green: 0.73, blue: 0.51), // #10b981
        "world": Color(red: 0.23, green: 0.51, blue: 0.96), // #3b82f6
        "politics": Color(red: 0.96, green: 0.62, blue: 0.04), // #f59e0b
        "technology": Color(red: 0.02, green: 0.71, blue: 0.83), // #06b6d4
        "weather": Color(red: 0.94, green: 0.27, blue: 0.27) // #ef4444
    ]
    
    @State private var selectedTab = 0
    @State private var selectedCategoryIndex = 0
    private let tabIcons = ["house", "bookmark", "gearshape"]
    @State private var viewModels: [PostsViewModel] = []
    @State private var allPosts: [Post] = []
    @State private var sseCancellable: AnyCancellable?
    @State private var pollingTimer: Timer? = nil
    @State private var sseClient = SSEClient()
    @State private var isConnected = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.10), // #0f1419
                    Color(red: 0.10, green: 0.12, blue: 0.18)  // #1a1f2e
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern Header
                HeaderView(
                    categories: categories,
                    categoryColors: categoryColors,
                    selectedCategoryIndex: selectedCategoryIndex,
                    viewModels: viewModels,
                    isConnected: isConnected,
                    pulseAnimation: pulseAnimation
                )
                
                // Responsive layout for categories and posts
                ResponsiveLayoutView(
                    categories: categories,
                    categoryColors: categoryColors,
                    viewModels: viewModels,
                    selectedCategoryIndex: $selectedCategoryIndex
                )
                
                // Modern TabBar
                TabBarView(
                    tabIcons: tabIcons,
                    selectedTab: $selectedTab
                )
            }
        }
        .onAppear {
            if viewModels.isEmpty {
                fetchAndDistributePosts()
            }
            setupSSE()
            startPulseAnimation()
        }
        .onDisappear {
            pollingTimer?.invalidate()
            pollingTimer = nil
            sseClient.disconnect()
        }
    }
    
    private func setupSSE() {
        sseClient.onConnect = {
            DispatchQueue.main.async {
                self.isConnected = true
                print("SSE: Connected successfully")
            }
        }
        
        sseClient.onDisconnect = {
            DispatchQueue.main.async {
                self.isConnected = false
                print("SSE: Disconnected")
            }
        }
        
        sseClient.onMessage = { message in
            
            // Extract the JSON string from the SSE message (strip 'data:' prefix)
            let lines = message.components(separatedBy: .newlines)
            guard let dataLine = lines.first(where: { $0.hasPrefix("data:") }) else { return }
            let jsonString = dataLine.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
            guard let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["type"] as? String != "ping" else {
                isConnected = true
                return
            }

            // Decode posts
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

            if let post = try? decoder.decode(Post.self, from: data) {

                DispatchQueue.main.async {
                    // Add to "all" category (always index 0 since "all" is first in categories array)
                    if let allViewModel = viewModels.first {
                        allViewModel.insertPost(post)
                    }
                    
                    // Add to "relevant" category if relevance >= 4 (index 1 since "relevant" is second)
                    if post.relevance >= 4, let relevantViewModel = viewModels[safe: 1] {
                        relevantViewModel.insertPost(post)
                    }
                    
                    // Add to specific categories
                    for (idx, cat) in categories.enumerated() {
                        if cat != "all" && cat != "relevant" && post.categories.contains(cat) {
                            if let vm = viewModels[safe: idx] {
                                vm.insertPost(post)
                            }
                        }
                    }
                }
            }
        }
        sseClient.connect(to: URL(string: "https://api.monitor.gaulatti.com/notifications")!)
    }
    
    private func startPulseAnimation() {
        pulseAnimation = true
    }

    // Add this helper function inside ContentView
    private func fetchAndDistributePosts() {
        guard let url = URL(string: "https://api.monitor.gaulatti.com/posts") else { return }
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
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let posts = try? decoder.decode([Post].self, from: data) else { return }
            DispatchQueue.main.async {
                allPosts = posts
                print("📊 Fetched \(posts.count) total posts")
                viewModels = categories.map { cat in
                    if cat == "all" {
                        // For "all" category, include all posts regardless of their categories
                        let vm = PostsViewModel(category: cat)
                        vm.posts = Array(posts.prefix(50)) // Show more posts for "all"
                        print("📋 'All' category: \(vm.posts.count) posts")
                        return vm
                    } else if cat == "relevant" {
                        // For "relevant" category, include posts with relevance >= 4
                        let relevantPosts = posts.filter { $0.relevance >= 4 }
                        let vm = PostsViewModel(category: cat)
                        vm.posts = Array(relevantPosts.prefix(30))
                        print("🔥 'Relevant' category: \(vm.posts.count) posts")
                        return vm
                    } else {
                        // For specific categories, filter by category
                        let filtered = posts.filter { $0.categories.contains(cat) }
                        let vm = PostsViewModel(category: cat)
                        vm.posts = Array(filtered.prefix(30))
                        print("📂 '\(cat)' category: \(vm.posts.count) posts")
                        return vm
                    }
                }
            }
        }.resume()
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
