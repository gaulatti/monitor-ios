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
    let author: String?  // Made optional since API sends null
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
        linkPreview = try container.decodeIfPresent(LinkPreview.self, forKey: .linkPreview)
        lang = try container.decodeIfPresent(String.self, forKey: .lang)
        
        // Handle media array with potential null values
        if let mediaArray = try container.decodeIfPresent([String?].self, forKey: .media) {
            media = mediaArray.compactMap { $0 } // Filter out null values
        } else {
            media = nil
        }
    }
    
    // Add memberwise initializer back
    init(id: String, content: String, source: String, posted_at: Date, categories: [String], author: String?, relevance: Int, authorName: String?, authorHandle: String?, authorAvatar: String?, uri: String?, media: [String]?, linkPreview: LinkPreview?, lang: String?) {
        self.id = id
        self.content = content
        self.source = source
        self.posted_at = posted_at
        self.categories = categories
        self.author = author
        self.relevance = relevance
        self.authorName = authorName
        self.authorHandle = authorHandle
        self.authorAvatar = authorAvatar
        self.uri = uri
        self.media = media
        self.linkPreview = linkPreview
        self.lang = lang
    }
    
    // Computed property to get the effective author name
    var effectiveAuthor: String {
        return authorName ?? author ?? "Unknown Author"
    }
}
