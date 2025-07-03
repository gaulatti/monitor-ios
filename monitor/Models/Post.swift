import Foundation

struct Post: Identifiable, Codable, Equatable {
    let id: String
    let content: String
    let source: String
    let posted_at: Date
    let categories: [String]
    let author: String
    let relevance: Int

    enum CodingKeys: String, CodingKey {
        case id, content, source, posted_at, categories, author, relevance
    }
}
