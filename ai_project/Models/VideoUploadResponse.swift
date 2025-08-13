import Foundation

struct VideoUploadResponse: Codable {
    let video_id: String
    let s3_url: String
    let message: String
}
