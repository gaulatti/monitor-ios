import Foundation
import Combine
import SwiftUI

// SSE-specific model that handles the extra fields in SSE data
struct SSEPostData: Codable {
    let id: String
    let content: String
    let source: String
    let posted_at: Date
    let categories: [String]
    let author: String?
    let relevance: Int
    let authorName: String?
    let authorHandle: String?
    let authorAvatar: String?
    let uri: String?
    let media: [String]?
    let linkPreview: String? // Note: SSE sends string instead of object
    let lang: String?
    // SSE-specific fields that we ignore
    let received_at: Date?
    let timestamp: Date?
    let original: String?
    let hash: String?
    let author_id: String?

    enum CodingKeys: String, CodingKey {
        case id, content, source, posted_at, categories, author, relevance, uri, media, lang, hash
        case authorName = "author_name"
        case authorHandle = "author_handle" 
        case authorAvatar = "author_avatar"
        case linkPreview = "linkPreview"
        case received_at, timestamp, original, author_id
    }
    
    // Custom initializer to handle null values in media array
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        source = try container.decode(String.self, forKey: .source)
        posted_at = try container.decode(Date.self, forKey: .posted_at)
        categories = try container.decode([String].self, forKey: .categories)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        relevance = try container.decode(Int.self, forKey: .relevance)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        authorHandle = try container.decodeIfPresent(String.self, forKey: .authorHandle)
        authorAvatar = try container.decodeIfPresent(String.self, forKey: .authorAvatar)
        uri = try container.decodeIfPresent(String.self, forKey: .uri)
        linkPreview = try container.decodeIfPresent(String.self, forKey: .linkPreview)
        lang = try container.decodeIfPresent(String.self, forKey: .lang)
        received_at = try container.decodeIfPresent(Date.self, forKey: .received_at)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
        original = try container.decodeIfPresent(String.self, forKey: .original)
        hash = try container.decodeIfPresent(String.self, forKey: .hash)
        author_id = try container.decodeIfPresent(String.self, forKey: .author_id)
        
        // Handle media array with potential null values
        if let mediaArray = try container.decodeIfPresent([String?].self, forKey: .media) {
            media = mediaArray.compactMap { $0 }
        } else {
            media = nil
        }
    }
    
    // Computed property to get the effective author name
    var effectiveAuthor: String {
        return authorName ?? author ?? "Unknown Author"
    }
}

class SSEClient: NSObject, URLSessionDataDelegate {
    private var session: URLSession!
    private var task: URLSessionDataTask?
    private var buffer = ""
    var isConnected = false

    var onMessage: ((String) -> Void)?
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func connect(to url: URL) {
        // Disconnect any existing connection first
        disconnect()

        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        self.task = session.dataTask(with: request)
        self.task?.resume()
        print("SSE: Attempting to connect to \(url)")
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        // Connection established
        DispatchQueue.main.async {
            self.isConnected = true
            self.onConnect?()
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        buffer += chunk

        while let range = buffer.range(of: "\n\n") {
            let event = buffer[..<range.lowerBound]
            buffer = String(buffer[range.upperBound...])

            // Parse SSE message properly
            let eventString = String(event)
            let lines = eventString.components(separatedBy: .newlines)
            
            var messageData: String?
            
            for line in lines {
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst("data: ".count))
                    messageData = jsonString
                    break
                }
            }
            
            guard let jsonData = messageData?.data(using: .utf8) else { continue }
            
            // Check if it's a ping message or connection message
            if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let type = json["type"] as? String {
                if type == "ping" || type == "connected" {
                    DispatchQueue.main.async {
                        self.isConnected = true
                    }
                    continue
                }
            }
            
            // Try to parse as Post
            do {
                let decoder = JSONDecoder()
                // Use custom date formatter for SSE that handles multiple formats
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                let iso8601Formatter = ISO8601DateFormatter()
                iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    // Try ISO8601 formatter first
                    if let date = iso8601Formatter.date(from: dateString) {
                        return date
                    }
                    
                    // Try custom formatter
                    if let date = dateFormatter.date(from: dateString) {
                        return date
                    }
                    
                    // Try without fractional seconds
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    if let date = dateFormatter.date(from: dateString) {
                        return date
                    }
                    
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(codingPath: decoder.codingPath,
                                            debugDescription: "Invalid date format: \(dateString)")
                    )
                }
                
                // First decode to extract the core Post fields and ignore SSE-specific fields
                let sseData = try decoder.decode(SSEPostData.self, from: jsonData)
                
                print("SSE Post successfully parsed - ID: \(sseData.id)")
                print("URI: \(sseData.uri ?? "nil")")
                print("Media count: \(sseData.media?.count ?? 0)")
                print("Author: \(sseData.effectiveAuthor)")
                print("Categories: \(sseData.categories)")
                
                DispatchQueue.main.async {
                    self.onMessage?(messageData ?? "")
                }
            } catch {
                print("SSE Post parsing error: \(error)")
                print("Failed JSON: \(messageData ?? "no data")")
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Connection ended (either normally or with error)
        DispatchQueue.main.async {
            self.isConnected = false
            self.onDisconnect?()
        }
    }

    func disconnect() {
        self.task?.cancel()
        self.task = nil
        self.buffer = ""
        self.isConnected = false
        print("SSE: Disconnected and buffer cleared")
    }
}
