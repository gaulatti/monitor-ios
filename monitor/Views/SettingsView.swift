//
//  SettingsView.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/18/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = false
    @State private var relevanceThreshold: Double = 5
    
    // Colors for the semaphore system
    private func thresholdColor(for value: Double) -> Color {
        switch value {
        case 0...5:
            return Color.green.opacity(0.8)
        case 6...7:
            return Color.orange.opacity(0.8)
        case 8...10:
            return Color.red.opacity(0.8)
        default:
            return Color.gray
        }
    }
    
    private func thresholdDescription(for value: Double) -> String {
        switch value {
        case 0...5:
            return "Low Priority"
        case 6...7:
            return "Medium Priority"
        case 8...10:
            return "High Priority"
        default:
            return ""
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.89, green: 0.91, blue: 0.92))
                
                Text("Configure your notification preferences")
                    .font(.bodyMedium)
                    .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Settings sections
            VStack(spacing: 16) {
                // Notifications toggle section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .font(.bodyMedium)
                            .foregroundColor(notificationsEnabled ? .blue : Color(red: 0.61, green: 0.64, blue: 0.69))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Push Notifications")
                                .font(.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.89, green: 0.91, blue: 0.92))
                            
                            Text("Receive notifications for important posts")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $notificationsEnabled)
                            .labelsHidden()
                            .tint(.blue)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(notificationsEnabled ? 0.3 : 0.1), lineWidth: 1)
                        )
                )
                
                // Relevance threshold section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .font(.bodyMedium)
                            .foregroundColor(notificationsEnabled ? thresholdColor(for: relevanceThreshold) : Color(red: 0.61, green: 0.64, blue: 0.69))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Relevance Threshold")
                                .font(.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(notificationsEnabled ? Color(red: 0.89, green: 0.91, blue: 0.92) : Color(red: 0.61, green: 0.64, blue: 0.69))
                            
                            Text("Minimum relevance level for notifications")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
                        }
                        
                        Spacer()
                    }
                    
                    if notificationsEnabled {
                        VStack(spacing: 12) {
                            // Current value display
                            HStack {
                                Text(String(format: "%.0f", relevanceThreshold))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(thresholdColor(for: relevanceThreshold))
                                
                                Text(thresholdDescription(for: relevanceThreshold))
                                    .font(.bodyMedium)
                                    .foregroundColor(thresholdColor(for: relevanceThreshold))
                                
                                Spacer()
                            }
                            
                            // Custom stepped slider
                            VStack(spacing: 8) {
                                HStack(spacing: 0) {
                                    ForEach(0...10, id: \.self) { step in
                                        let isActive = Double(step) <= relevanceThreshold
                                        let stepColor = thresholdColor(for: Double(step))
                                        
                                        Rectangle()
                                            .fill(isActive ? stepColor : Color(red: 0.3, green: 0.3, blue: 0.3))
                                            .frame(height: 8)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 0.5)
                                            )
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    relevanceThreshold = Double(step)
                                                }
                                                // Haptic feedback
                                                let impact = UIImpactFeedbackGenerator(style: .light)
                                                impact.impactOccurred()
                                            }
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                
                                // Step labels
                                HStack {
                                    Text("0")
                                        .font(.caption2)
                                        .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
                                    
                                    Spacer()
                                    
                                    Text("5")
                                        .font(.caption2)
                                        .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
                                    
                                    Spacer()
                                    
                                    Text("10")
                                        .font(.caption2)
                                        .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(notificationsEnabled ? thresholdColor(for: relevanceThreshold).opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
                        )
                )
                .opacity(notificationsEnabled ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.3), value: notificationsEnabled)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09)) // Same dark background as the app
    }
}

#Preview {
    SettingsView()
}
