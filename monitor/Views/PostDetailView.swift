//
//  PostDetailView.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/18/25.
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    let categoryColors: [String: Color]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var navigationManager = NavigationManager.shared
    
    private var accentColor: Color {
        if let firstCategory = post.categories.first {
            return categoryColors[firstCategory] ?? .blue
        }
        return .blue
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header section
                    VStack(alignment: .leading, spacing: 12) {
                        // Categories and relevance
                        HStack {
                            ForEach(post.categories, id: \.self) { category in
                                Text(category.uppercased())
                                    .font(.libreFranklinSemiBold(size: 12))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(categoryColors[category] ?? .blue, in: RoundedRectangle(cornerRadius: 4))
                            }
                            
                            Spacer()
                            
                            // Relevance indicator
                            if post.relevance > 0 {
                                HStack(spacing: 2) {
                                    ForEach(0..<post.relevance, id: \.self) { _ in
                                        Circle()
                                            .fill(accentColor)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                            }
                        }
                        
                        // Timestamp and author
                        HStack {
                            Text(post.posted_at.formatted(date: .abbreviated, time: .shortened))
                                .font(.libreFranklinMedium(size: 14))
                                .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
                            
                            Spacer()
                            
                            if !post.effectiveAuthor.isEmpty {
                                Text(post.effectiveAuthor)
                                    .font(.libreFranklinMedium(size: 12))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(accentColor, in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                    
                    // Content
                    Text(post.content)
                        .font(.libreFranklinRegular(size: 16))
                        .foregroundColor(Color(red: 0.89, green: 0.91, blue: 0.92))
                        .lineSpacing(4)
                    
                    // Media section
                    if post.uri != nil || (post.media?.isEmpty == false) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Links & Media")
                                .font(.libreFranklinSemiBold(size: 14))
                                .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
                            
                            MediaSectionView(post: post)
                        }
                    }
                    
                    // Source information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source")
                            .font(.libreFranklinSemiBold(size: 14))
                            .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
                        
                        Text(post.source)
                            .font(.libreFranklinMedium(size: 14))
                            .foregroundColor(Color(red: 0.89, green: 0.91, blue: 0.92))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
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
                .padding(20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.06, green: 0.08, blue: 0.10),
                        Color(red: 0.10, green: 0.12, blue: 0.18)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        PostSharingUtility.sharePost(post)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

#Preview {
    PostDetailView(
        post: Post(
            id: "test-1",
            content: "This is a test post for the detail view. It should show all the content in a clean, readable format with proper spacing and typography.",
            source: "test",
            posted_at: Date(),
            categories: ["technology", "test"],
            author: "Test Author",
            relevance: 8,
            authorName: "Test Author Full Name",
            authorHandle: "@testauthor",
            authorAvatar: "https://example.com/avatar.jpg",
            uri: "https://example.com/original-post",
            media: [MediaItem(url: "https://example.com/image1.jpg")],
            linkPreview: nil as LinkPreview?,
            lang: "en",
            hash: "sample-hash-123",
            uuid: "sample-uuid-456",
            matchScore: 0.85
        ),
        categoryColors: [
            "technology": Color(red: 0.02, green: 0.71, blue: 0.83),
            "test": Color.blue
        ]
    )
}
