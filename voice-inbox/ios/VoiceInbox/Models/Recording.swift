import Foundation

struct Recording: Identifiable, Codable {
    let id: String
    let text: String
    let audioURL: URL?
    var tag: String?
    var pending: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case audioURL = "audio_url"
        case tag
        case pending
        case createdAt = "created_at"
    }
} 