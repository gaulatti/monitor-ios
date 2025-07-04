//
//  monitorApp.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 6/27/25.
//

import SwiftUI
import SwiftData

@main
struct monitorApp: App {
    init() {
            registerFonts()
        }
    
    private func registerFonts() {
        [
                "libre-franklin.bold",
                "libre-franklin.light",
                "libre-franklin.medium",
                "libre-franklin.regular",
                "libre-franklin.semibold"
            ].forEach { registerFont(named: $0, fileExtension: "ttf") }
        }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    private func registerFont(named: String, fileExtension: String) {
            guard let fontURL = Bundle.main.url(forResource: named, withExtension: fileExtension) else {
                print("Font file not found: \(named).\(fileExtension)")
                return
            }

            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)

            if !success {
                let errorDescription = CFErrorCopyDescription(error?.takeUnretainedValue())
                print("Failed to register font \(named): \(String(describing: errorDescription))")
            }
        }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Verify fonts are loaded in debug builds
                    #if DEBUG
                    for family in UIFont.familyNames {
                        print("Font family: \(family)")
                        for name in UIFont.fontNames(forFamilyName: family) {
                            print("   ↳ \(name)")
                        }
                    }
                    #endif
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
