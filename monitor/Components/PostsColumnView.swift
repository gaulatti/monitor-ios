//
//  PostsColumnView.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/2/25.
//
import SwiftUI

struct PostsColumnView: View {
    @ObservedObject var viewModel: PostsViewModel
    @StateObject private var notificationManager = NotificationManager.shared

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
                            
                            // Relevance indicator
                            HStack(spacing: 4) {
                                Text("\(post.relevance)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(relevanceColor(for: post.relevance))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(relevanceColor(for: post.relevance).opacity(0.2))
                                    )
                                
                                Text(post.posted_at, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        Color(.systemGray5)
                            .overlay(
                                // Highlight posts that meet relevance threshold
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        meetsRelevanceThreshold(post) ? 
                                        relevanceColor(for: post.relevance).opacity(0.6) : 
                                        Color.clear, 
                                        lineWidth: 1
                                    )
                            )
                    )
                    .cornerRadius(8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding()
        }
    }
    
    // Helper function to determine if post meets relevance threshold
    private func meetsRelevanceThreshold(_ post: Post) -> Bool {
        return Double(post.relevance) >= notificationManager.relevanceThreshold
    }
    
    // Helper function to get color based on relevance score
    private func relevanceColor(for relevance: Int) -> Color {
        switch relevance {
        case 0...3:
            return Color.gray
        case 4...6:
            return Color.orange
        case 7...8:
            return Color.red
        case 9...10:
            return Color.purple
        default:
            return Color.gray
        }
    }
}
