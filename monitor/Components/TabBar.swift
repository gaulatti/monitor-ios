//
//  TabBar.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/2/25.
//

import SwiftUI

struct TabBarView: View {
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
                    Image(systemName: tabIcons[idx])
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(selectedTab == idx ? accentColor : secondaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
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
                        .scaleEffect(selectedTab == idx ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
    }
}
