import Foundation

struct VideoUploadResponse: Codable {
    let videoId: String
    let analysisId: String
    let signedVideoUrl: String
    let signedThumbnailUrl: String
    let videoExpiresAt: String
    let thumbnailExpiresAt: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
        case analysisId = "analysis_id"
        case signedVideoUrl = "signed_video_url"
        case signedThumbnailUrl = "signed_thumbnail_url"
        case videoExpiresAt = "video_expires_at"
        case thumbnailExpiresAt = "thumbnail_expires_at"
        case message
    }
}
