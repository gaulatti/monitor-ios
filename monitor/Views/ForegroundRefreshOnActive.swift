//
//  ForegroundRefreshOnActive.swift
//  monitor
//
//  Created by AI Assistant for foreground refresh functionality
//

import SwiftUI

/// A view modifier that refreshes PostsViewModel instances when the app returns to foreground
struct ForegroundRefreshOnActive: ViewModifier {
    let viewModels: [PostsViewModel]
    @Environment(\.scenePhase) private var scenePhase
    @State private var previousScenePhase: ScenePhase?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(from: oldPhase, to: newPhase)
            }
    }
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        // Only trigger refresh when transitioning to active from background or inactive
        guard newPhase == .active else { return }
        guard oldPhase == .background || oldPhase == .inactive else { return }
        
        print("🚀 App returned to foreground - triggering top refresh for all PostsViewModel instances")
        
        // Trigger top refresh for all view models
        for viewModel in viewModels {
            viewModel.fetchTopAndPrepend()
        }
        
        // Send analytics about foreground refresh
        NotificationManager.shared.sendAnalytics(event: "app_foreground_refresh", data: [
            "viewModels_count": viewModels.count,
            "categories": viewModels.map { $0.category }
        ])
    }
}

extension View {
    /// Applies foreground refresh behavior to PostsViewModel instances
    func foregroundRefreshOnActive(viewModels: [PostsViewModel]) -> some View {
        self.modifier(ForegroundRefreshOnActive(viewModels: viewModels))
    }
}