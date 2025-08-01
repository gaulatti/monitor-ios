//
//  NotificationService.swift
//  notifications
//
//  Created by Javier Godoy Núñez on 7/20/25.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else { 
            contentHandler(request.content)
            return 
        }

        // Enhance notification content
        // Note: iOS automatically uses the app icon for notifications
        // We can enhance the notification with additional metadata
        
        // Add app-specific styling
        if let postId = request.content.userInfo["postId"] as? String {
            bestAttemptContent.categoryIdentifier = "POST_NOTIFICATION"
            bestAttemptContent.threadIdentifier = "monitor-posts"
            
            // Add action buttons for post notifications
            bestAttemptContent.subtitle = "Monitor Alert"
        }

        contentHandler(bestAttemptContent)
    }
    
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
