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
    private let categories = ["all", "business", "world", "politics", "technology", "weather"]
    private let categoryColors: [String: Color] = [
        "all": Color(red: 0.75, green: 0.75, blue: 0.75), // #c0c0c0 - neutral gray for all
        "business": Color(red: 0.06, green: 0.73, blue: 0.51), // #10b981
        "world": Color(red: 0.23, green: 0.51, blue: 0.96), // #3b82f6
        "politics": Color(red: 0.96, green: 0.62, blue: 0.04), // #f59e0b
        "technology": Color(red: 0.02, green: 0.71, blue: 0.83), // #06b6d4
        "weather": Color(red: 0.94, green: 0.27, blue: 0.27) // #ef4444
    ]
    
    @State private var selectedTab = 0
    @State private var selectedCategoryIndex = 0
    private let tabItems = ["Home", "Bookmarks", "Settings"]
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
                    tabItems: tabItems,
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
                    
                    // Add to specific categories
                    for (idx, cat) in categories.enumerated() {
                        if cat != "all" && post.categories.contains(cat) {
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

struct PostsColumnView: View {
    @ObservedObject var viewModel: PostsViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.posts) { post in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.content)
                            .font(.body)
                        HStack {
                            Text(post.source)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(post.posted_at, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding()
        }
    }
}

// MARK: - Modern Posts Column View
struct ModernPostsColumnView: View {
    @ObservedObject var viewModel: PostsViewModel
    let accentColor: Color
    let category: String
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.posts) { post in
                    ModernPostCard(post: post, accentColor: accentColor)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Modern Post Card
struct ModernPostCard: View {
    let post: Post
    let accentColor: Color
    @State private var isPressed = false
    
    var relevanceOpacity: Double {
        Double(post.relevance) / 10.0 * 0.1 + 0.05
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Content
            Text(post.content)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(red: 0.89, green: 0.91, blue: 0.92)) // #e4e7eb
                .lineLimit(nil)
            
            // Footer
            HStack(spacing: 8) {
                // Source badge
                Text(post.source.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor, in: RoundedRectangle(cornerRadius: 4))
                
                // Author
                if !post.author.isEmpty {
                    Text(post.author)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69)) // #9ca3af
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Timestamp
                Text(post.posted_at.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69)) // #9ca3af
            }
            
            // Relevance indicator
            if post.relevance > 0 {
                HStack {
                    ForEach(0..<post.relevance, id: \.self) { _ in
                        Circle()
                            .fill(accentColor)
                            .frame(width: 4, height: 4)
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor.opacity(relevanceOpacity))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            // Animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Responsive Layout View
struct ResponsiveLayoutView: View {
    let categories: [String]
    let categoryColors: [String: Color]
    let viewModels: [PostsViewModel]
    @Binding var selectedCategoryIndex: Int
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 600 {
                // Wide screen: Multi-column layout like web
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(categories.indices, id: \.self) { idx in
                            VStack(alignment: .leading, spacing: 12) {
                                // Category header
                                HStack {
                                    Text(categories[idx].uppercased())
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(categoryColors[categories[idx]] ?? .blue)
                                    Spacer()
                                    Text("(\(viewModels[safe: idx]?.posts.count ?? 0))")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                
                                // Posts column
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        if let viewModel = viewModels[safe: idx] {
                                            let postsToShow = categories[idx] == "all" ? 15 : 10 // Show more for "all"
                                            ForEach(viewModel.posts.prefix(postsToShow)) { post in
                                                CompactPostCard(post: post, accentColor: categoryColors[categories[idx]] ?? .blue)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 16)
                                }
                            }
                            .frame(width: min(geometry.size.width * 0.9, 300))
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke((categoryColors[categories[idx]] ?? .blue).opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                // Narrow screen: Single column with category tabs
                VStack(spacing: 0) {
                    // Category tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(categories.indices, id: \.self) { idx in
                                Button(action: {
                                    selectedCategoryIndex = idx
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }) {
                                    Text(categories[idx].uppercased())
                                        .font(.system(size: 14, weight: .semibold, design: .default))
                                        .foregroundColor(selectedCategoryIndex == idx ? .white : Color(red: 0.61, green: 0.64, blue: 0.69))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Group {
                                                if selectedCategoryIndex == idx {
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .fill(categoryColors[categories[idx]] ?? .blue)
                                                } else {
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(Color(red: 0.61, green: 0.64, blue: 0.69).opacity(0.3), lineWidth: 1)
                                                }
                                            }
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 8)
                    
                    // Selected category content
                    if selectedCategoryIndex < categories.count {
                        ModernPostsColumnView(
                            viewModel: viewModels[safe: selectedCategoryIndex] ?? PostsViewModel(category: categories[selectedCategoryIndex]),
                            accentColor: categoryColors[categories[selectedCategoryIndex]] ?? .blue,
                            category: categories[selectedCategoryIndex]
                        )
                        .animation(.easeInOut(duration: 0.3), value: selectedCategoryIndex)
                    }
                }
            }
        }
    }
}

// MARK: - Compact Post Card for Multi-Column Layout
struct CompactPostCard: View {
    let post: Post
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.content)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.89, green: 0.91, blue: 0.92))
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 6) {
                Text(post.source.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor, in: RoundedRectangle(cornerRadius: 3))
                
                Spacer()
                
                Text(post.posted_at.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// Array safe subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
