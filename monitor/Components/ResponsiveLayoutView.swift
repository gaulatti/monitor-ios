//
//  ResponsiveLayoutView.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/2/25.
//
import SwiftUI

struct ResponsiveLayoutView: View {
    let categories: [String]
    let categoryColors: [String: Color]
    let viewModels: [PostsViewModel]
    @Binding var selectedCategoryIndex: Int
    
    var body: some View {
                // Single column layout with category tabs
                VStack(spacing: 0) {
                    // Category tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(categories.indices, id: \.self) { idx in
                                Button(action: {
                                    selectedCategoryIndex = idx
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }) {
                                    Text(categories[idx].uppercased())
                                        .font(.libreFranklinSemiBold(size: 14))
                                        .foregroundColor(
                                            selectedCategoryIndex == idx ? .white : 
                                            (categories[idx] == "all" ? .blue : (categoryColors[categories[idx]] ?? .blue))
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Group {
                                                if selectedCategoryIndex == idx {
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .fill(categories[idx] == "all" ? .blue : (categoryColors[categories[idx]] ?? .blue))
                                                } else {
                                                    if categories[idx] == "all" {
                                                        // Ghost button style with subtle border for "all" only
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .stroke(.blue.opacity(0.2), lineWidth: 1)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 20)
                                                                    .fill(.clear)
                                                            )
                                                    } else {
                                                        // Regular style for other categories
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .stroke((categoryColors[categories[idx]] ?? .blue).opacity(0.3), lineWidth: 1)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 20)
                                                                    .fill((categoryColors[categories[idx]] ?? .blue).opacity(0.1))
                                                            )
                                                    }
                                                }
                                            }
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 8)

                    // Selected category content
                    if selectedCategoryIndex < categories.count {
                        ModernPostsColumnView(
                            viewModel: viewModels[safe: selectedCategoryIndex] ?? PostsViewModel(category: categories[selectedCategoryIndex]),
                            categoryColors: categoryColors,
                            category: categories[selectedCategoryIndex]
                        )
                        .animation(.easeInOut(duration: 0.3), value: selectedCategoryIndex)
                    }
                }
    }
}
