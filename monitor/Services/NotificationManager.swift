//
//  NotificationManager.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/18/25.
//

import Foundation
import UIKit
import UserNotifications

class NotificationManager: ObservableObject {
  static let shared = NotificationManager()

  @Published var isAuthorized = false
  @Published var relevanceThreshold: Double {
    didSet {
      // Always store as integer to avoid floating point issues
      let intValue = Int(relevanceThreshold.rounded())
      UserDefaults.standard.set(intValue, forKey: "notificationRelevanceThreshold")
      
      // Only update if the value actually changed to avoid infinite recursion
      let roundedValue = Double(intValue)
      if relevanceThreshold != roundedValue {
        relevanceThreshold = roundedValue
      }
    }
  }
  
  // Queue for pending analytics events before device registration
  private var pendingAnalytics: [(event: String, data: [String: Any])] = []

  private init() {
    // Load saved threshold, default to 5 (as integer)
    let savedThreshold = UserDefaults.standard.object(forKey: "notificationRelevanceThreshold") as? Int ?? 5
    self.relevanceThreshold = Double(savedThreshold)

    checkAuthorizationStatus()
  }

  func checkAuthorizationStatus() {
    UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
      DispatchQueue.main.async {
        self?.isAuthorized =
          settings.authorizationStatus == .authorized
          || settings.authorizationStatus == .provisional
      }
    }
  }

  func requestPermission() async -> Bool {
    do {
      let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [
        .alert, .badge, .sound,
      ])

      await MainActor.run {
        self.isAuthorized = granted
        if granted {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }

      return granted
    } catch {
      print("❌ Error requesting notification permission: \(error)")
      return false
    }
  }

  func scheduleTestNotification() {
    guard isAuthorized else { return }

    let content = UNMutableNotificationContent()
    content.title = "Monitor Test"
    content.body =
      "Push notifications are working! You'll receive notifications for posts with relevance ≥ \(Int(relevanceThreshold))"
    content.sound = .default
    content.badge = 1

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
    let request = UNNotificationRequest(
      identifier: "test-notification", content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("❌ Error scheduling test notification: \(error)")
      } else {
        print("✅ Test notification scheduled")
      }
    }
  }

  func shouldShowNotification(for post: Post) -> Bool {
    return isAuthorized && Double(post.relevance) >= relevanceThreshold
  }

  func sendDeviceTokenToServer(_ token: String) {
    guard let url = URL(string: "https://api.monitor.gaulatti.com/devices") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Get app info
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    let bundleId = Bundle.main.bundleIdentifier ?? "com.gaulatti.ios.monitor"

    // Get device info
    let deviceModel = UIDevice.current.model
    let systemVersion = UIDevice.current.systemVersion
    let timeZone = TimeZone.current.identifier

    // Generate a unique device/installation ID if not exists
    let deviceId = getOrCreateDeviceId()

    let body: [String: Any] = [
      "deviceToken": token,
      "platform": "ios",
      "relevanceThreshold": Int(relevanceThreshold.rounded()), // Send as integer
      "isActive": isAuthorized,
      "deviceInfo": [
        "deviceId": deviceId,
        "model": deviceModel,
        "systemVersion": systemVersion,
        "appVersion": appVersion,
        "buildNumber": buildNumber,
        "bundleId": bundleId,
        "timeZone": timeZone,
        "language": Locale.current.languageCode ?? "en",
      ],
      "preferences": [
        "categories": ["all", "relevant"],  // Default categories, could be made configurable
        "quietHours": false,  // Could be enhanced with quiet hours feature
      ],
      "registeredAt": ISO8601DateFormatter().string(from: Date()),
    ]

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: body)

      URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
          print("❌ Failed to send device token to server: \(error.localizedDescription)")
        } else if let httpResponse = response as? HTTPURLResponse {
          if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            print("✅ Device token sent to server successfully")
            UserDefaults.standard.set(true, forKey: "deviceTokenRegistered")
            UserDefaults.standard.set(Date(), forKey: "lastTokenRegistration")

            // Parse response to get server device ID if provided
            if let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let serverId = json["id"] as? String
            {
              UserDefaults.standard.set(serverId, forKey: "serverDeviceId")
              print("✅ Server device ID: \(serverId)")
            }
            
            // Send any pending analytics events now that device is registered
            self.sendPendingAnalytics()
          } else {
            print("⚠️ Server responded with status code: \(httpResponse.statusCode)")
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
              print("Response: \(responseString)")
            }
          }
        }
      }.resume()
    } catch {
      print("❌ Error serializing device token request: \(error)")
    }
  }

  func updateServerSettings() {
    guard let deviceToken = UserDefaults.standard.string(forKey: "deviceToken"),
      UserDefaults.standard.bool(forKey: "deviceTokenRegistered")
    else { return }

    guard let url = URL(string: "https://api.monitor.gaulatti.com/devices/\(deviceToken)") else {
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
      "relevanceThreshold": Int(relevanceThreshold.rounded()), // Send as integer
      "isActive": isAuthorized,
      "lastUpdated": ISO8601DateFormatter().string(from: Date()),
    ]

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: body)

      URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
          print("❌ Failed to update server settings: \(error.localizedDescription)")
        } else if let httpResponse = response as? HTTPURLResponse {
          if httpResponse.statusCode == 200 {
            print("✅ Server settings updated successfully")
          } else {
            print("⚠️ Server responded with status code: \(httpResponse.statusCode)")
          }
        }
      }.resume()
    } catch {
      print("❌ Error serializing settings update request: \(error)")
    }
  }

  // MARK: - Private Helper Methods

  private func getOrCreateDeviceId() -> String {
    if let existingId = UserDefaults.standard.string(forKey: "deviceId") {
      return existingId
    }

    let newId = UUID().uuidString
    UserDefaults.standard.set(newId, forKey: "deviceId")
    return newId
  }

  // MARK: - Post Tracking Methods

  func markPostAsRead(_ postId: String) {
    // Track that user has seen this post (to avoid duplicate notifications)
    guard let deviceToken = UserDefaults.standard.string(forKey: "deviceToken") else { 
      print("⚠️ No device token available, skipping mark as read for post: \(postId)")
      return 
    }
    
    // If we have a token but device isn't registered yet, register it first
    if !UserDefaults.standard.bool(forKey: "deviceTokenRegistered") {
      print("🔄 Device token available but not registered, registering now...")
      sendDeviceTokenToServer(deviceToken)
      // Don't queue read events - they're less critical than analytics
      return
    }

    guard let url = URL(string: "https://api.monitor.gaulatti.com/devices/\(deviceToken)/read")
    else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
      "postId": postId,
      "readAt": ISO8601DateFormatter().string(from: Date()),
    ]

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: body)

      URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
          print("❌ Failed to mark post as read: \(error.localizedDescription)")
        } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
          print("✅ Post \(postId) marked as read")
        }
      }.resume()
    } catch {
      print("❌ Error serializing read post request: \(error)")
    }
  }

  func sendAnalytics(event: String, data: [String: Any] = [:]) {
    // Send analytics to help with notification optimization
    guard let deviceToken = UserDefaults.standard.string(forKey: "deviceToken") else { 
      print("⚠️ No device token available, queuing analytics event: \(event)")
      pendingAnalytics.append((event: event, data: data))
      return 
    }
    
    // If we have a token but device isn't registered yet, register it first
    if !UserDefaults.standard.bool(forKey: "deviceTokenRegistered") {
      print("🔄 Device token available but not registered, registering now...")
      sendDeviceTokenToServer(deviceToken)
      // Queue this event to be sent after registration
      pendingAnalytics.append((event: event, data: data))
      return
    }

    sendAnalyticsEvent(event: event, data: data, deviceToken: deviceToken)
  }
  
  private func sendAnalyticsEvent(event: String, data: [String: Any], deviceToken: String) {
    guard let url = URL(string: "https://api.monitor.gaulatti.com/analytics") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    var body: [String: Any] = [
      "deviceToken": deviceToken,
      "event": event,
      "timestamp": ISO8601DateFormatter().string(from: Date()),
      "platform": "ios",
    ]

    // Merge additional data
    body.merge(data) { (_, new) in new }

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: body)

      URLSession.shared.dataTask(with: request) { _, response, error in
        if let error = error {
          print("❌ Failed to send analytics: \(error.localizedDescription)")
        } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
          print("✅ Analytics event '\(event)' sent")
        }
      }.resume()
    } catch {
      print("❌ Error serializing analytics request: \(error)")
    }
  }
  
  // Send any queued analytics events after device registration
  private func sendPendingAnalytics() {
    guard let deviceToken = UserDefaults.standard.string(forKey: "deviceToken"),
          UserDefaults.standard.bool(forKey: "deviceTokenRegistered") else { return }
    
    print("📤 Sending \(pendingAnalytics.count) pending analytics events")
    
    for pendingEvent in pendingAnalytics {
      sendAnalyticsEvent(event: pendingEvent.event, data: pendingEvent.data, deviceToken: deviceToken)
    }
    
    // Clear the pending queue
    pendingAnalytics.removeAll()
  }
}
