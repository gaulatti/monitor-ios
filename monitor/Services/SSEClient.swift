import Foundation
import Combine
import SwiftUI

class SSEClient: NSObject, URLSessionDataDelegate {
    private var session: URLSession!
    private var task: URLSessionDataTask?
    private var buffer = ""

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

            let message = event.dropFirst(5).trimmingCharacters(in: .whitespaces)
            
            // Debug: Log received message structure
            if !message.isEmpty {
                print("SSE Raw message received: \(message.prefix(200))...")
                
                // Try to parse as Post to verify field mapping
                if let data = message.data(using: .utf8) {
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let post = try decoder.decode(Post.self, from: data)
                        print("SSE Post successfully parsed - ID: \(post.id)")
                        print("URI: \(post.uri ?? "nil")")
                        print("Media count: \(post.media?.count ?? 0)")
                        print("Author: \(post.author)")
                        print("Categories: \(post.categories)")
                    } catch {
                        print("SSE Post parsing error: \(error)")
                        print("Failed message: \(message)")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.onMessage?(message)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Connection ended (either normally or with error)
        DispatchQueue.main.async {
            self.onDisconnect?()
        }
    }

    func disconnect() {
        self.task?.cancel()
        self.task = nil
        self.buffer = ""
        print("SSE: Disconnected and buffer cleared")
    }
}
