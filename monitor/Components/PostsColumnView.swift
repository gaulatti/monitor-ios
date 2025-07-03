//
//  PostsColumnView.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/2/25.
//
import SwiftUI

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
