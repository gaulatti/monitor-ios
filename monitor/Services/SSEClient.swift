import Foundation
import Combine
import SwiftUI
import EventSource

//class SSEClient: NSObject, ObservableObject {
//    private var eventSourceTask: Task<Void, Never>?
//    private let url: URL
//    private let subject = PassthroughSubject<Post, Never>()
//    var publisher: AnyPublisher<Post, Never> { subject.eraseToAnyPublisher() }
//    private var shouldReconnect = true
//
//    init(url: URL) {
//        self.url = url
//        super.init()
//    }
//
//    func connect() {
//        disconnect()
//        shouldReconnect = true
//        startEventSource()
//    }
//
//    private func startEventSource() {
//        var request = URLRequest(url: url)
//        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
//        eventSourceTask = Task { [weak self] in
//            guard let self = self else { return }
//            print("SSE: Attempting to connect...")
//            let eventSource = EventSource()
//            let dataTask = await eventSource.dataTask(for: request)
//            for await event in await dataTask.events() {
//                switch event {
//                case .open:
//                    print("SSE: Connection was opened.")
//                case .error(let error):
//                    print("SSE: Received an error:", error.localizedDescription)
//                    await self.handleReconnect()
//                case .event(let event):
//                    if let data = event.data, let jsonData = data.data(using: .utf8) {
//                        if let post = try? JSONDecoder().decode(Post.self, from: jsonData) {
//                            print("SSE: Received:", post)
//                            DispatchQueue.main.async {
//                                self.subject.send(post)
//                            }
//                        }
//                    }
//                case .closed:
//                    print("SSE: Connection was closed.")
//                    await self.handleReconnect()
//                }
//            }
//        }
//    }
//
//    private func handleReconnect() async {
//        guard shouldReconnect else { return }
//        if shouldReconnect {
//            startEventSource()
//        }
//    }
//
//    func disconnect() {
//        shouldReconnect = false
//        eventSourceTask?.cancel()
//        eventSourceTask = nil
//    }
//}


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
