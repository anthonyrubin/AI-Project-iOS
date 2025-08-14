import Foundation

struct VideoUploadResponse: Codable {
    let videoId: String
    let analysisId: String
    let s3Url: String
    let thumbnailUrl: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
        case analysisId = "analysis_id"
        case s3Url = "s3_url"
        case thumbnailUrl = "thumbnail_url"
        case message
    }
}
