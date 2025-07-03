//
//  TabBar.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/2/25.
//

import SwiftUI

struct TabBarView: View {
    let tabItems: [String]
    let tabIcons: [String]
    @Binding var selectedTab: Int
    var accentColor: Color = Color(red: 0.23, green: 0.51, blue: 0.96)
    var secondaryColor: Color = Color(red: 0.61, green: 0.64, blue: 0.69)

    var body: some View {
        HStack {
            ForEach(tabItems.indices, id: \.self) { idx in
                Button(action: {
                    selectedTab = idx
                    // Haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabIcons[idx])
                            .font(.system(size: 20, weight: .medium))
                        Text(tabItems[idx])
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(selectedTab == idx ? accentColor : secondaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if selectedTab == idx {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .scaleEffect(selectedTab == idx ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}
