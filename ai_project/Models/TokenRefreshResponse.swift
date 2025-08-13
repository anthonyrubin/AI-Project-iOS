import Foundation

struct TokenRefreshResponse: Codable {
    let access: String
    let refresh: String
}
