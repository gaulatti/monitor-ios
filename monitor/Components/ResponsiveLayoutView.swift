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
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                let threshold: CGFloat = 50
                let horizontalAmount = value.translation.width
                
                if abs(horizontalAmount) > threshold {
                    let currentIndex = selectedCategoryIndex
                    let maxIndex = categories.count - 1
                    
                    if horizontalAmount > 0 {
                        // Swipe right - go to previous category
                        let newIndex = max(0, currentIndex - 1)
                        if newIndex != currentIndex {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            selectedCategoryIndex = newIndex
                        }
                    } else {
                        // Swipe left - go to next category
                        let newIndex = min(maxIndex, currentIndex + 1)
                        if newIndex != currentIndex {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            selectedCategoryIndex = newIndex
                        }
                    }
                }
            }
    }
    
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
                        let currentViewModel = viewModels[safe: selectedCategoryIndex] ?? PostsViewModel(category: categories[selectedCategoryIndex])
                        let currentCategory = categories[selectedCategoryIndex]
                        
                        ModernPostsColumnView(
                            viewModel: currentViewModel,
                            categoryColors: categoryColors,
                            category: currentCategory
                        )
                        .animation(.easeInOut(duration: 0.3), value: selectedCategoryIndex)
                        .gesture(swipeGesture)
                    }
                }
    }
}
