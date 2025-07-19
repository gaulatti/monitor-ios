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
    @Environment(\.scenePhase) private var scenePhase

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
                // Main content based on selected tab
                if selectedTab == 0 || selectedTab == 1 {
                    // Home and Bookmarks tabs (currently same content)
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
                    }
                } else if selectedTab == 2 {
                    // Settings tab
                    SettingsView()
                }

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

            // Send app opened analytics
            NotificationManager.shared.sendAnalytics(event: "app_opened")
        }
        .onDisappear {
            pollingTimer?.invalidate()
            pollingTimer = nil
            sseClient.disconnect()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
        .preferredColorScheme(.dark)
    }
    
    private func setupSSE() {
        // Disconnect any existing connection first
        sseClient.disconnect()
        
        // Create a new SSE client instance to ensure clean state
        sseClient = SSEClient()
        
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
        
        sseClient.onMessage = { jsonString in
            // The SSE client now sends the clean JSON string directly
            guard let data = jsonString.data(using: .utf8) else { return }

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
                print("✅ ContentView: Successfully decoded SSE post - \(post.id)")

                // Send analytics about received post
                NotificationManager.shared.sendAnalytics(event: "post_received_sse", data: [
                    "postId": post.id,
                    "relevance": post.relevance,
                    "categories": post.categories
                ])

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
            } else {
                print("❌ ContentView: Failed to decode SSE message as Post")
            }
        }
        sseClient.connect(to: URL(string: "https://api.monitor.gaulatti.com/notifications")!)
    }

    private func startPulseAnimation() {
        pulseAnimation = true
    }

    // Add this helper function inside ContentView
    private func fetchAndDistributePosts() {
        print("🔄 Fetching fresh posts from server...")

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
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                return
            }

            guard let data = data else { 
                print("❌ No data received")
                return 
            }

            // Log first part of response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 API Response (first 500 chars): \(String(responseString.prefix(500)))")
            }

                do {
                let posts = try decoder.decode([Post].self, from: data)
                print("✅ Successfully decoded \(posts.count) posts")

                // Send analytics about posts fetched
                NotificationManager.shared.sendAnalytics(event: "posts_fetched", data: [
                    "count": posts.count,
                    "source": "api"
                ])

                DispatchQueue.main.async {
                    allPosts = posts
                    print("📊 Fetched \(posts.count) total posts")

                    // Create new view models with fresh data
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
                print("✅ Data refresh completed successfully")
            }
            } catch {
                print("❌ Failed to decode posts: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Missing key: \(key.stringValue) in \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch for type \(type) in \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Value not found for type \(type) in \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                return 
            }
        }.resume()
    }

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active (foreground)
            if oldPhase == .background || oldPhase == .inactive {
                print("🚀 App returned to foreground - refreshing data and reconnecting SSE")
                NotificationManager.shared.sendAnalytics(event: "app_foreground")
                refreshAppData()
            }
        case .background:
            // App went to background
            print("📱 App went to background - disconnecting SSE")
            NotificationManager.shared.sendAnalytics(event: "app_background")
            cleanupConnections()
        case .inactive:
            // App became inactive (transitioning)
            break
        @unknown default:
            break
        }
    }
    
    private func refreshAppData() {
        // Clear existing data
        clearAllData()
        
        // Re-fetch posts and re-establish SSE connection
        fetchAndDistributePosts()
        setupSSE()
        startPulseAnimation()
    }
    
    private func clearAllData() {
        // Clear all posts from view models
        for viewModel in viewModels {
            viewModel.posts.removeAll()
        }
        
        // Clear the main posts array
        allPosts.removeAll()
        
        // Reset connection state
        isConnected = false
        pulseAnimation = false
        
        print("🧹 Cleared all data - ready for fresh start")
    }
    
    private func cleanupConnections() {
        // Disconnect SSE
        sseClient.disconnect()
        
        // Cancel any timers
        pollingTimer?.invalidate()
        pollingTimer = nil
        
        // Update connection state
        isConnected = false
        pulseAnimation = false
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
