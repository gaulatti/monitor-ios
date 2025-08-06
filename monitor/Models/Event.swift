import Foundation

// Wrapper for the API response
struct EventsResponse: Codable {
    let events: [Event]
    let total: Int
}

// Post type specifically for events (posts within events have different structure)
struct EventPost: Codable, Identifiable {
    let id: Int
    let uuid: String
    let title: String
    let content: String
    let imageUrl: String?
    let url: String?
    let score: Int
    let author_name: String
    let author_handle: String
    let createdAt: String
    let hash: String
    let match_score: Double
    
    private enum CodingKeys: String, CodingKey {
        case id, uuid, title, content, score, hash, url
        case imageUrl = "image_url"
        case author_name, author_handle
        case createdAt
        case match_score
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as either Int or String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id) {
            self.id = Int(idString) ?? 0
        } else {
            self.id = 0
        }
        
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.score = try container.decode(Int.self, forKey: .score)
        self.author_name = try container.decode(String.self, forKey: .author_name)
        self.author_handle = try container.decode(String.self, forKey: .author_handle)
        self.createdAt = try container.decode(String.self, forKey: .createdAt)
        self.hash = try container.decode(String.self, forKey: .hash)
        self.match_score = try container.decode(Double.self, forKey: .match_score)
    }
    
    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt)
    }
}

struct Event: Codable, Identifiable {
    let id: Int
    let uuid: String
    let title: String
    let summary: String
    let status: String
    let created_at: String
    let updated_at: String
    let posts_count: Int
    let posts: [EventPost]?
    
    // Computed properties for UI
    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: created_at)
    }
    
    var updatedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: updated_at)
    }
    
    var statusColor: String {
        switch status.lowercased() {
        case "open":
            return "#10b981" // Green
        case "archived":
            return "#6b7280" // Gray
        case "dismissed":
            return "#ef4444" // Red
        default:
            return "#8b5cf6" // Purple (default)
        }
    }
    
    var formattedCreatedDate: String {
        guard let date = createdDate else { return "Unknown" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // For SwiftUI previews and testing
    static func mockEvent() -> Event {
        return Event(
            id: 1,
            uuid: "12345678-1234-1234-1234-123456789012",
            title: "Sample Event Title",
            summary: "This is a sample event summary describing what the event is about.",
            status: "open",
            created_at: "2025-08-05T10:30:00.000Z",
            updated_at: "2025-08-05T11:00:00.000Z",
            posts_count: 5,
            posts: []
        )
    }
}

// Custom Equatable implementation
extension Event: Equatable {
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.uuid == rhs.uuid && lhs.updated_at == rhs.updated_at
    }
}
