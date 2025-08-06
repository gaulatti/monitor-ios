import Foundation

class EventsService: ObservableObject {
    private let baseURL = "https://api.monitor.gaulatti.com"
    
    @Published var events: [Any] = [] // Temporarily using Any until proper Event import is resolved
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - API Methods
    
    func fetchEvents(limit: Int? = nil) {
        isLoading = true
        errorMessage = nil
        
        var urlComponents = URLComponents(string: "\(baseURL)/events")!
        if let limit = limit {
            urlComponents.queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]
        }
        
        guard let url = urlComponents.url else {
            print("❌ Invalid events URL")
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        print("🔄 Fetching events from: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Log HTTP response details
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Response Status: \(httpResponse.statusCode)")
                print("📡 HTTP Response Headers: \(httpResponse.allHeaderFields)")
            }
            
            if let error = error {
                print("❌ Network Error: \(error)")
                print("❌ Error Description: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                print("❌ No data received for events")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "No data received"
                }
                return
            }
            
            // Log raw data details
            print("📊 Received data size: \(data.count) bytes")
            
            // Log first 500 characters of response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                let preview = String(responseString.prefix(500))
                print("📄 Response preview: \(preview)")
                if responseString.count > 500 {
                    print("📄 (Response truncated - total length: \(responseString.count) characters)")
                }
            } else {
                print("⚠️ Could not convert response data to UTF-8 string")
            }
            
            do {
                print("🔍 Attempting to decode as generic JSON first...")
                
                // First, try to decode as generic JSON to see the structure
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("✅ Successfully parsed as JSON object")
                    print("🔍 Top-level keys: \(jsonObject.keys.sorted())")
                    
                    if let events = jsonObject["events"] as? [[String: Any]] {
                        print("📊 Found 'events' array with \(events.count) items")
                        if let firstEvent = events.first {
                            print("🎯 First event keys: \(firstEvent.keys.sorted())")
                        }
                    } else {
                        print("⚠️ No 'events' key found or not an array")
                    }
                    
                    if let total = jsonObject["total"] {
                        print("📊 Total value: \(total) (type: \(type(of: total)))")
                    }
                } else {
                    print("❌ Failed to parse as JSON object")
                }
                
                print("⚠️ Structured decoding not implemented in this version")
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.events = [] // Empty for now
                }
            } catch let decodingError as DecodingError {
                print("❌ Decoding Error Details:")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("   Type mismatch: \(type) at path: \(context.codingPath)")
                    print("   Debug description: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("   Value not found: \(type) at path: \(context.codingPath)")
                    print("   Debug description: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    print("   Key not found: \(key) at path: \(context.codingPath)")
                    print("   Debug description: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("   Data corrupted at path: \(context.codingPath)")
                    print("   Debug description: \(context.debugDescription)")
                @unknown default:
                    print("   Unknown decoding error: \(decodingError)")
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to parse events data: \(decodingError.localizedDescription)"
                }
            } catch {
                print("❌ General Error: \(error)")
                print("❌ Error Type: \(type(of: error))")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to parse events data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // Note: This EventsService is currently not used - EventsView has debug implementation
}
