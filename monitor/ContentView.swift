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
    private let tabIcons = ["house", "calendar", "gearshape"]
    @State private var viewModels: [PostsViewModel] = []
    @State private var sseCancellable: AnyCancellable?
    @State private var pollingTimer: Timer? = nil
    @State private var sseClient = SSEClient()
    @State private var isConnected = false
    @State private var pulseAnimation = false
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var navigationManager = NavigationManager.shared
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
                if selectedTab == 0 {
                    // Home tab - Posts
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
                } else if selectedTab == 1 {
                    // Events tab
                    EventsView()
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
        .onChange(of: notificationManager.relevanceThreshold) { oldThreshold, newThreshold in
            print("🎯 Relevance threshold changed from \(oldThreshold) to \(newThreshold) - updating relevant category")
            updateRelevantCategory()
        }
        // Handle deep link navigation from notifications
        .onChange(of: navigationManager.deepLinkPostId) { oldPostId, newPostId in
            if let postId = newPostId {
                handleDeepLinkToPost(postId: postId)
            }
        }
        // Present post detail sheet
        .sheet(isPresented: $navigationManager.showPostDetail) {
            if let selectedPost = navigationManager.selectedPost {
                PostDetailView(post: selectedPost, categoryColors: categoryColors)
                    .onDisappear {
                        navigationManager.dismissPostDetail()
                    }
            }
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

                    // Add to "relevant" category if relevance meets user's threshold (index 1 since "relevant" is second)
                    if Double(post.relevance) >= notificationManager.relevanceThreshold, let relevantViewModel = viewModels[safe: 1] {
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
        print("🔄 Setting up view models with pagination...")
        
        // Create new view models for each category
        viewModels = categories.map { cat in
            let vm = PostsViewModel(category: cat)
            if cat == "relevant" {
                vm.relevanceThreshold = notificationManager.relevanceThreshold
            }
            return vm
        }
        
        // Trigger initial fetch for each category
        for viewModel in viewModels {
            viewModel.fetchInitial()
        }
        
        print("✅ View models setup completed")
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
            viewModel.hasMore = true
            viewModel.isLoadingMore = false
        }
        
        // Reset connection state
        isConnected = false
        pulseAnimation = false
        
        print("🧹 Cleared all data - ready for fresh start")
    }
    
    private func handleDeepLinkToPost(postId: String) {
        print("🔗 ContentView: Handling deep link to post \(postId)")
        
        // Search for the post in all loaded posts across all view models
        var foundPost: Post?
        for viewModel in viewModels {
            if let post = viewModel.posts.first(where: { $0.id == postId }) {
                foundPost = post
                break
            }
        }
        
        if let post = foundPost {
            print("✅ Found post for deep link: \(post.id)")
            navigationManager.navigateToPost(post)
            navigationManager.deepLinkPostId = nil // Clear the deep link
        } else {
            print("⚠️ Post \(postId) not found in current data")
            
            // For testing purposes, create a mock post if it's the test post ID
            if postId == "test-post-id" {
                print("🧪 Creating test post for deep link testing")
                let testPost = Post(
                    id: "test-post-id",
                    content: "This is a test post created for deep linking from notifications. If you're seeing this, the notification deep linking feature is working correctly!",
                    source: "test-notification",
                    posted_at: Date(),
                    categories: ["test", "notification"],
                    author: "System",
                    relevance: 10,
                    authorName: "Monitor System",
                    authorHandle: "@monitor",
                    authorAvatar: nil as String?,
                    uri: "https://monitor.gaulatti.com",
                    media: nil as [MediaItem]?,
                    linkPreview: nil,
                    lang: "en",
                    hash: "test-deeplink-hash",
                    uuid: "test-deeplink-uuid",
                    matchScore: nil as Double?
                )
                navigationManager.navigateToPost(testPost)
            }
            
            navigationManager.deepLinkPostId = nil // Clear the deep link
        }
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
    
    private func updateRelevantCategory() {
        // Find the "relevant" category view model (index 1)
        guard let relevantViewModel = viewModels[safe: 1] else { return }
        
        // Update threshold and re-fetch
        relevantViewModel.relevanceThreshold = notificationManager.relevanceThreshold
        relevantViewModel.fetchInitial()
        
        print("🔄 Updating 'Relevant' category with threshold \(notificationManager.relevanceThreshold)")
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
