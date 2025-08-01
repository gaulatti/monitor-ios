//
//  monitorApp.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 6/27/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct monitorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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

// MARK: - AppDelegate for handling push notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Register notification categories and actions
        setupNotificationCategories()
        
        return true
    }
    
    private func setupNotificationCategories() {
        // Define actions for post notifications
        let readAction = UNNotificationAction(
            identifier: "READ_ACTION",
            title: "Mark as Read",
            options: []
        )
        
        let openAction = UNNotificationAction(
            identifier: "OPEN_ACTION", 
            title: "Open",
            options: [.foreground]
        )
        
        // Create category for post notifications
        let postCategory = UNNotificationCategory(
            identifier: "POST_NOTIFICATION",
            actions: [readAction, openAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register the categories
        UNUserNotificationCenter.current().setNotificationCategories([postCategory])
    }
    
    // Called when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("🔔 Device Token: \(token)")
        
        // Store token in UserDefaults
        UserDefaults.standard.set(token, forKey: "deviceToken")
        
        // Send token to server via NotificationManager
        NotificationManager.shared.sendDeviceTokenToServer(token)
    }
    
    // Called when registration for remote notifications fails
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Called when a notification is delivered to a foreground app
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📱 Notification received in foreground: \(notification.request.content.title)")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Called when user taps on a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👆 User tapped notification: \(response.notification.request.content.title)")
        
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "READ_ACTION":
            // User marked as read without opening app
            if let postId = userInfo["postId"] as? String {
                print("📖 Marking post \(postId) as read from notification")
                NotificationManager.shared.markPostAsRead(postId)
            }
            
        case "OPEN_ACTION", UNNotificationDefaultActionIdentifier:
            // User wants to open the app/post
            if let postId = userInfo["postId"] as? String {
                print("📰 Opening post with ID: \(postId)")
                // Navigate to specific post using NavigationManager
                NavigationManager.shared.handleDeepLink(postId: postId)
            }
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            print("🚫 User dismissed notification")
            
        default:
            break
        }
        
        completionHandler()
    }
}
