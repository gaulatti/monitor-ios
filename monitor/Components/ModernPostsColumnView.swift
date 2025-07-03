//
//  ModernPostsColumnView.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/2/25.
//
import SwiftUI

struct ModernPostsColumnView: View {
    @ObservedObject var viewModel: PostsViewModel
    let categoryColors: [String: Color]
    let category: String
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.posts) { post in
                    ModernPostCard(post: post, categoryColors: categoryColors, columnCategory: category)
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
