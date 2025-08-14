import Foundation

// MARK: - Video Analysis Models

struct VideoAnalysis: Codable {
    let id: Int
    let video: Video
    let analysis_data: [String: AnyCodable]  // Raw JSON from AI analysis
    let sport: String
    let sport_category: String
    let professional_score: Double?
    let confidence: Double?
    let clip_summary: String
    let overall_tips: [String]
    let metrics_catalog: [String]
    let created_at: String
    
    // Computed properties to extract data from analysis_data
    var events: [AnalysisEvent]? {
        guard let eventsData = analysis_data["events"]?.value as? [[String: Any]] else { return nil }
        return eventsData.compactMap { (eventDict: [String: Any]) -> AnalysisEvent? in
            guard let t = eventDict["t"] as? Double,
                  let label = eventDict["label"] as? String,
                  let feedback = eventDict["feedback"] as? String,
                  let metricsData = eventDict["metrics"] as? [[String: Any]] else { return nil }
            
            let metrics = metricsData.compactMap { (metricDict: [String: Any]) -> AnalysisMetric? in
                guard let name = metricDict["name"] as? String,
                      let value = metricDict["value"] as? String,
                      let estimationMethod = metricDict["estimation_method"] as? String else { return nil }
                return AnalysisMetric(name: name, value: value, estimation_method: estimationMethod)
            }
            
            return AnalysisEvent(t: t, label: label, metrics: metrics, feedback: feedback)
        }
    }
    
    // Custom decoding to handle potential issues
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        video = try container.decode(Video.self, forKey: .video)
        analysis_data = try container.decode([String: AnyCodable].self, forKey: .analysis_data)
        sport = try container.decode(String.self, forKey: .sport)
        sport_category = try container.decode(String.self, forKey: .sport_category)
        professional_score = try container.decodeIfPresent(Double.self, forKey: .professional_score)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        clip_summary = try container.decode(String.self, forKey: .clip_summary)
        overall_tips = try container.decode([String].self, forKey: .overall_tips)
        metrics_catalog = try container.decode([String].self, forKey: .metrics_catalog)
        created_at = try container.decode(String.self, forKey: .created_at)
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

struct AnalysisEvent: Codable {
    let t: Double  // timestamp
    let label: String
    let metrics: [AnalysisMetric]
    let feedback: String
}

struct AnalysisMetric: Codable {
    let name: String
    let value: String
    let estimation_method: String
}

struct Video: Codable {
    let id: Int
    let s3_url: String
    let thumbnail_url: String?
    let original_filename: String
    let file_size: Int
    let duration: Double?
    let uploaded_at: String
}

// MARK: - Delta Sync Response
struct DeltaSyncResponse: Codable {
    let analyses: [VideoAnalysis]
    let sync_timestamp: String
    let has_more: Bool
}
