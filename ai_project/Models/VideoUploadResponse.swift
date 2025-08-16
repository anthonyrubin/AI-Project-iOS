import Foundation

struct VideoUploadResponse: Codable {
    let videoId: String
    let analysisId: String
    let videoGcsUrl: String
    let thumbnailGcsUrl: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
        case analysisId = "analysis_id"
        case videoGcsUrl = "video_gcs_url"
        case thumbnailGcsUrl = "thumbnail_gcs_url"
        case message
    }
}
