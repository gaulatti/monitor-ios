//
//  ModernPostCard.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/2/25.
//
import SwiftUI

struct ModernPostCard: View {
    let post: Post
    let categoryColors: [String: Color]
    let columnCategory: String
    @State private var isPressed = false
    @State private var isLongPressed = false
    @StateObject private var navigationManager = NavigationManager.shared
    
    var accentColor: Color {
        if columnCategory.lowercased() == "all" {
            // In "All" column, use the color of the first category in the post
            if let firstCategory = post.categories.first {
                return categoryColors[firstCategory] ?? .blue
            }
            return .blue
        } else {
            // In specific category columns, use the column's category color
            return categoryColors[columnCategory] ?? .blue
        }
    }
    
    var relevanceOpacity: Double {
        Double(post.relevance) / 10.0 * 0.1 + 0.05
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with timestamp and author
            HStack(spacing: 8) {
                Text(post.posted_at.formatted(date: .omitted, time: .shortened))
                    .font(.bodyMedium)
                    .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69)) // #9ca3af
                
                Spacer()
                
                // Author badge (if available)
                if !post.effectiveAuthor.isEmpty {
                    Text(post.effectiveAuthor)
                        .font(.subMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor, in: RoundedRectangle(cornerRadius: 3))
                        .lineLimit(1)
                }
            }
            
            // Content
            Text(post.content)
                .font(.bodyMedium)
                .foregroundColor(Color(red: 0.89, green: 0.91, blue: 0.92)) // #e4e7eb
                .lineLimit(nil)
                .padding(.top, 2)
            
            // Media section (NEW - consolidated media/links)
            if post.uri != nil || (post.media?.isEmpty == false) {
                MediaSectionView(post: post)
                    .padding(.top, 6)
            }
            
            // Relevance indicator at bottom
            if post.relevance > 0 {
                HStack {
                    ForEach(0..<post.relevance, id: \.self) { _ in
                        Circle()
                            .fill(accentColor)
                            .frame(width: 3, height: 3)
                    }
                    Spacer()
                }
                .padding(.top, 6)
            }
        }
        .padding(10)
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
        .scaleEffect(isPressed ? 0.98 : (isLongPressed ? 0.95 : 1.0))
        .opacity(isLongPressed ? 0.8 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isLongPressed)
        .onTapGesture {
            // Ensure all tap operations are on main thread
            DispatchQueue.main.async {
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                
                // Animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = true
                }
                
                // Navigate to post detail
                navigationManager.navigateToPost(post)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 10, pressing: { pressing in
            // Immediate visual feedback during long press - ensure on main thread
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isLongPressed = pressing
                }
            }
        }) {
            // Ensure all actions are on main thread to prevent UI hangs
            DispatchQueue.main.async {
                // Small delay to ensure UI state has settled
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // Haptic feedback only when long press completes successfully
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred()
                    
                    // Share to WhatsApp (already on main thread)
                    PostSharingUtility.sharePost(post)
                }
            }
        }
    }
}
