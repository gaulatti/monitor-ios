//
//  URLExtensions.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/4/25.
//

import Foundation
import UIKit

extension String {
    func getUrlHostname() -> String? {
        // Skip non-HTTP protocols like at://, did:, etc.
        guard self.hasPrefix("http://") || self.hasPrefix("https://") else {
            return nil
        }
        
        guard let url = URL(string: self) else {
            return nil
        }
        
        return url.host
    }
    
    func isImageUrl() -> Bool {
        guard let url = URL(string: self) else { return false }
        
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "svg", "bmp", "ico"]
        let pathExtension = url.pathExtension.lowercased()
        
        return imageExtensions.contains(pathExtension)
    }
}

enum MediaError: Error {
    case unsupportedProtocol
    case invalidUrl
    case loadFailed
}

func openURL(_ urlString: String) {
    guard urlString.hasPrefix("http://") || urlString.hasPrefix("https://"),
          let url = URL(string: urlString) else {
        print("Invalid or unsupported URL protocol: \(urlString)")
        return
    }
    
    UIApplication.shared.open(url)
}
