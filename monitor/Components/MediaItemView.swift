//
//  MediaItemView.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/4/25.
//

import SwiftUI

struct MediaImageView: View {
    let mediaUrl: String
    let originalUri: String?
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadError = false
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(6)
            } else if isLoading {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            } else {
                // Fallback if image fails to load
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Overlay link button - links to original post URI, not image
            if image != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { openOriginalLink() }) {
                            Image(systemName: "link")
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(6)
                    }
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // Check cache first
        if let cachedImage = ImageCache.shared.getImage(for: mediaUrl) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        guard let url = URL(string: mediaUrl) else {
            loadError = true
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data, let uiImage = UIImage(data: data) {
                    // Cache the image
                    ImageCache.shared.setImage(uiImage, for: mediaUrl)
                    self.image = uiImage
                } else {
                    self.loadError = true
                }
            }
        }.resume()
    }
    
    private func openOriginalLink() {
        // CRITICAL: Prefer original post URI over media URL
        let targetUrl = originalUri ?? mediaUrl
        openURL(targetUrl)
    }
}

struct MediaItemView: View {
    let mediaUrl: String
    let originalUri: String?
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadError = false
    
    var body: some View {
        if mediaUrl.isImageUrl() {
            // Image preview with overlay
            MediaImageView(mediaUrl: mediaUrl, originalUri: originalUri)
        } else {
            // Regular link for non-images
            MediaLinkView(url: mediaUrl, hostname: mediaUrl.getUrlHostname() ?? "Unknown")
        }
    }
}

struct MediaLinkView: View {
    let url: String
    let hostname: String
    
    var body: some View {
        Button(action: { openURL(url) }) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                    .font(.caption2)
                Text(hostname)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.blue)
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
