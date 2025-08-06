import Foundation

struct LinkPreview: Codable, Equatable {
    let title: String?
    let description: String?
    let image: String?
    let url: String?
}

struct MediaItem: Codable, Equatable {
    let url: String?
    let type: String?
    let width: Int?
    let height: Int?
    let alt: String?
    
    // Convenience initializer for creating MediaItem from URL string
    init(url: String?, type: String? = nil, width: Int? = nil, height: Int? = nil, alt: String? = nil) {
        self.url = url
        self.type = type
        self.width = width
        self.height = height
        self.alt = alt
    }
    
    // Fallback init for when media is still a string
    init(from decoder: Decoder) throws {
        // First try to decode as a dictionary/object
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            url = try container.decodeIfPresent(String.self, forKey: .url)
            type = try container.decodeIfPresent(String.self, forKey: .type)
            width = try container.decodeIfPresent(Int.self, forKey: .width)
            height = try container.decodeIfPresent(Int.self, forKey: .height)
            alt = try container.decodeIfPresent(String.self, forKey: .alt)
        } else {
            // If that fails, try to decode as a single string value
            let singleValue = try decoder.singleValueContainer()
            url = try singleValue.decode(String.self)
            type = nil
            width = nil
            height = nil
            alt = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case url, type, width, height, alt
    }
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
    let media: [MediaItem]?
    let linkPreview: LinkPreview?
    let lang: String?
    let hash: String?
    let uuid: String?
    let matchScore: Double?

    enum CodingKeys: String, CodingKey {
        case id, content, source, categories, author, relevance, hash, uuid, uri, media, lang
        case posted_at  // API uses posted_at directly
        case authorName = "author_name"
        case authorHandle = "author_handle" 
        case authorAvatar = "author_avatar"
        case linkPreview = "link_preview"
        case matchScore = "match_score"
    }
    
    // Custom initializer to handle different formats from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle ID - can be Int or String from API
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        content = try container.decode(String.self, forKey: .content)
        source = try container.decode(String.self, forKey: .source)
        relevance = try container.decode(Int.self, forKey: .relevance)
        
        // Handle date - API sends posted_at as ISO string
        if let dateString = try? container.decode(String.self, forKey: .posted_at) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            posted_at = formatter.date(from: dateString) ?? Date()
        } else {
            posted_at = try container.decode(Date.self, forKey: .posted_at)
        }
        
        // Categories might be missing in events API
        categories = try container.decodeIfPresent([String].self, forKey: .categories) ?? []
        
        author = try container.decodeIfPresent(String.self, forKey: .author)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        authorHandle = try container.decodeIfPresent(String.self, forKey: .authorHandle)
        authorAvatar = try container.decodeIfPresent(String.self, forKey: .authorAvatar)
        uri = try container.decodeIfPresent(String.self, forKey: .uri)
        linkPreview = try container.decodeIfPresent(LinkPreview.self, forKey: .linkPreview)
        lang = try container.decodeIfPresent(String.self, forKey: .lang)
        hash = try container.decodeIfPresent(String.self, forKey: .hash)
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
        matchScore = try container.decodeIfPresent(Double.self, forKey: .matchScore)
        
        // Handle media array - can be strings or objects or missing
        if container.contains(.media) {
            do {
                // First try to decode as array of MediaItem objects
                media = try container.decodeIfPresent([MediaItem].self, forKey: .media)
            } catch {
                print("⚠️ Media decoding as objects failed: \(error)")
                // If that fails, try to decode as array of strings (backwards compatibility)
                do {
                    if let stringArray = try container.decodeIfPresent([String?].self, forKey: .media) {
                        media = stringArray.compactMap { urlString in
                            guard let urlString = urlString else { return nil }
                            return try? MediaItem(from: DummyDecoder(value: urlString))
                        }
                    } else {
                        media = nil
                    }
                } catch {
                    print("⚠️ Media decoding as strings also failed: \(error)")
                    // Last resort - set to empty array
                    media = []
                }
            }
        } else {
            media = nil
        }
        
        // The new properties are already initialized above when decoding
    }
    
    // Add memberwise initializer back
    init(id: String, content: String, source: String, posted_at: Date, categories: [String], author: String?, relevance: Int, authorName: String?, authorHandle: String?, authorAvatar: String?, uri: String?, media: [MediaItem]?, linkPreview: LinkPreview?, lang: String?, hash: String?, uuid: String?, matchScore: Double?) {
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
        self.hash = hash
        self.uuid = uuid
        self.matchScore = matchScore
    }
    
    // Computed property to get the effective author name
    var effectiveAuthor: String {
        return authorName ?? author ?? "Unknown Author"
    }
}

// Helper for backwards compatibility
struct DummyDecoder: Decoder {
    let value: String
    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey: Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: [], debugDescription: "Not a keyed container"))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: [], debugDescription: "Not an unkeyed container"))
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return DummySingleValueContainer(value: value)
    }
}

struct DummySingleValueContainer: SingleValueDecodingContainer {
    let value: String
    let codingPath: [CodingKey] = []
    
    func decodeNil() -> Bool { false }
    func decode(_ type: Bool.Type) throws -> Bool { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not a bool")) }
    func decode(_ type: String.Type) throws -> String { value }
    func decode(_ type: Double.Type) throws -> Double { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not a double")) }
    func decode(_ type: Float.Type) throws -> Float { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not a float")) }
    func decode(_ type: Int.Type) throws -> Int { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not an int")) }
    func decode(_ type: Int8.Type) throws -> Int8 { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not an int8")) }
    func decode(_ type: Int16.Type) throws -> Int16 { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not an int16")) }
    func decode(_ type: Int32.Type) throws -> Int32 { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not an int32")) }
    func decode(_ type: Int64.Type) throws -> Int64 { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not an int64")) }
    func decode(_ type: UInt.Type) throws -> UInt { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not a uint")) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not a uint8")) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not a uint16")) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not a uint32")) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not a uint64")) }
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Not decodable")) }
}
