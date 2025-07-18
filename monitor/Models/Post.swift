import Foundation

struct LinkPreview: Codable, Equatable {
    let title: String?
    let description: String?
    let image: String?
    let url: String?
}

struct Post: Identifiable, Codable, Equatable {
    let id: String
    let content: String
    let source: String
    let posted_at: Date
    let categories: [String]
    let author: String
    let relevance: Int
    let authorName: String?
    let authorHandle: String?
    let authorAvatar: String?
    let uri: String?
    let media: [String]?
    let linkPreview: LinkPreview?
    let lang: String?

    enum CodingKeys: String, CodingKey {
        case id, content, source, posted_at, categories, author, relevance
        case authorName = "author_name"
        case authorHandle = "author_handle" 
        case authorAvatar = "author_avatar"
        case uri, media, linkPreview = "link_preview", lang
    }
}
