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
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        self.task = session.dataTask(with: request)
        self.task?.resume()
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
    }
}
