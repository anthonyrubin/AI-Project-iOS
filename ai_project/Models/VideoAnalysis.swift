import Foundation

// MARK: - Video Analysis Models

struct VideoAnalysis: Codable {
    let id: Int
    let video: Video
    let analysis_data: [String: AnyCodable]  // Raw JSON from AI analysis
    let icon: String
    let sport: String
    let sport_category: String
    let lift_score: Int?
    let confidence: Double?
    let overall_analysis: String
    let strengths: [Strength]
    let areas_for_improvement: [AreaForImprovement]
    let created_at: String
    
    
    // Custom decoding to handle potential issues
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        video = try container.decode(Video.self, forKey: .video)
        analysis_data = try container.decode([String: AnyCodable].self, forKey: .analysis_data)
        sport = try container.decode(String.self, forKey: .sport)
        sport_category = try container.decode(String.self, forKey: .sport_category)
        lift_score = try container.decodeIfPresent(Int.self, forKey: .lift_score)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        overall_analysis = try container.decode(String.self, forKey: .overall_analysis)
        strengths = try container.decode([Strength].self, forKey: .strengths)
        areas_for_improvement = try container.decode([AreaForImprovement].self, forKey: .areas_for_improvement)
        created_at = try container.decode(String.self, forKey: .created_at)
        icon = try container.decode(String.self, forKey: .icon)
    }
}

// Helper struct to handle Any JSON values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}


// MARK: - New Analysis Structure

struct Strength: Codable {
    let title: String
    let analysis: String
}

struct AreaForImprovement: Codable {
    let title: String
    let analysis: String
    let actionable_tips: [String]
    let corrective_drills: [String]
}

struct Video: Codable {
    let id: Int
    let signedVideoUrl: String
    let signedThumbnailUrl: String
    let videoExpiresAt: String
    let thumbnailExpiresAt: String
    let original_filename: String
    let file_size: Int
    let duration: Double?
    let uploaded_at: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case signedVideoUrl = "signed_video_url"
        case signedThumbnailUrl = "signed_thumbnail_url"
        case videoExpiresAt = "video_expires_at"
        case thumbnailExpiresAt = "thumbnail_expires_at"
        case original_filename
        case file_size
        case duration
        case uploaded_at
    }
}

// MARK: - Delta Sync Response
struct DeltaSyncResponse: Codable {
    let analyses: [VideoAnalysis]
    let sync_timestamp: String
    let has_more: Bool
}

// MARK: - URL Refresh Response
struct UrlRefreshResponse: Codable {
    let refreshed_urls: [RefreshedUrl]
    let message: String
}

struct RefreshedUrl: Codable {
    let video_id: Int
    let signed_video_url: String
    let signed_thumbnail_url: String
    let video_expires_at: String
    let thumbnail_expires_at: String
    let error: String?
}


