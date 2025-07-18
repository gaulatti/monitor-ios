//
//  MediaSectionView.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/4/25.
//

import SwiftUI

struct MediaSectionView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // All links stacked vertically (both original and media links)
            VStack(alignment: .leading, spacing: 3) {
                // Original post link (if available)
                if let uri = post.uri, let hostname = uri.getUrlHostname() {
                    Button(action: { openURL(uri) }) {
                        HStack {
                            Image(systemName: "link")
                                .font(.bodyMedium)
                            Text("Original (\(hostname))")
                                .font(.bodyMedium)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.bodyMedium)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Media links (non-images only) - stacked vertically
                if let media = post.media {
                    ForEach(Array(media.enumerated()), id: \.offset) { index, mediaUrl in
                        if !mediaUrl.isImageUrl(), let hostname = mediaUrl.getUrlHostname() {
                            Button(action: { openURL(post.uri ?? mediaUrl) }) {
                                HStack {
                                    Image(systemName: "link")
                                        .font(.bodyMedium)
                                    Text(hostname)
                                        .font(.bodyMedium)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.bodyMedium)
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            
            // Images in a separate grid below the links
            if let media = post.media {
                let imageUrls = media.filter { $0.isImageUrl() }
                if !imageUrls.isEmpty {
                    VStack(spacing: 4) {
                        ForEach(Array(imageUrls.prefix(3).enumerated()), id: \.offset) { index, mediaUrl in
                            MediaImageView(mediaUrl: mediaUrl, originalUri: post.uri)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 0)
    }
}
