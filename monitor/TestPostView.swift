//
//  TestPostView.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/4/25.
//

import SwiftUI
import Foundation

struct TestPostView: View {
    let testPost = Post(
        id: "test-1",
        content: "This is a test post with image preview functionality and media links. Testing URL validation and media handling.",
        source: "test",
        posted_at: Date(),
        categories: ["technology", "test"],
        author: "Test Author",
        relevance: 8,
        authorName: "Test Author Full Name",
        authorHandle: "@testauthor",
        authorAvatar: "https://example.com/avatar.jpg",
        uri: "https://example.com/original-post",
        media: [
            MediaItem(url: "https://example.com/image1.jpg"),
            MediaItem(url: "https://example.com/document.pdf"),
            MediaItem(url: "https://invalid-protocol.at://should-be-ignored")
        ],
        linkPreview: LinkPreview(
            title: "Test Link Preview",
            description: "This is a test link preview",
            image: "https://example.com/preview.jpg",
            url: "https://example.com/original-post"
        ),
        lang: "en",
        hash: "test-hash-789",
        uuid: "test-uuid-012",
        matchScore: 0.92
    )
    
    let categoryColors: [String: Color] = [
        "technology": Color(red: 0.02, green: 0.71, blue: 0.83),
        "test": Color.blue
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Enhanced Post Card Test")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                
                ModernPostCard(
                    post: testPost,
                    categoryColors: categoryColors,
                    columnCategory: "technology"
                )
                .padding()
                
                Text("Media Section Test")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                
                MediaSectionView(post: testPost)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                
                Text("URL Validation Test")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Valid HTTP URL: \("https://example.com".getUrlHostname() ?? "nil")")
                        .foregroundColor(.green)
                    Text("Valid HTTPS URL: \("https://secure.example.com".getUrlHostname() ?? "nil")")
                        .foregroundColor(.green)
                    Text("Invalid AT protocol: \("at://did.example.com".getUrlHostname() ?? "nil")")
                        .foregroundColor(.red)
                    Text("Invalid DID protocol: \("did:example:123".getUrlHostname() ?? "nil")")
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                Spacer()
            }
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
        .ignoresSafeArea()
    }
}

#Preview {
    TestPostView()
}
