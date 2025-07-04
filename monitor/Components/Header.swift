//
//  Header.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/2/25.
//

import SwiftUI

struct HeaderView: View {
    let categories: [String]
    let categoryColors: [String: Color]
    let selectedCategoryIndex: Int
    let viewModels: [PostsViewModel]
    let isConnected: Bool
    let pulseAnimation: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // App title with gradient
                Text("monitor")
                    .font(.appTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.23, green: 0.51, blue: 0.96),
                                Color(red: 0.02, green: 0.71, blue: 0.83)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
                // Live status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(isConnected ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                        .opacity(pulseAnimation ? 1.0 : 0.3)
                        .animation(.easeInOut(duration: 1.0).repeatForever(), value: pulseAnimation)
                    Text(isConnected ? "LIVE" : "OFFLINE")
                        .font(.caption)
                        .foregroundColor(isConnected ? .green : .gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
}
