//
//  NotificationService.swift
//  productAlert
//
//  Created by Gershon Kagan on 3/19/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            
            if let attachmentURLString = request.content.userInfo["media-url"] as? String,
              let attachmentURL = URL(string: attachmentURLString) {
                let uniqueId = UUID().uuidString
                let tmpImageFileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(uniqueId).appendingPathExtension(attachmentURL.pathExtension)
                print("NotificationService saving media from:\(attachmentURL)  to:\(tmpImageFileUrl)")
                do {
                    let imageData = try Data(contentsOf: attachmentURL)
                    try imageData.write(to: tmpImageFileUrl)
                    let attachment = try UNNotificationAttachment(identifier: uniqueId,
                                                                  url: tmpImageFileUrl,
                                                                  options: nil)
                    bestAttemptContent.attachments = [attachment]
                } catch {
                    print("NotificationService attachment error:\(error)")
                }
            } else {
                print("NotificationService failed to form attachmentURL from userInfo:\(String(describing: request.content.userInfo))")
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
