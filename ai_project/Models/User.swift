import Foundation

struct User: Codable {
    let id: Int
    let app_account_token: UUID
    let username: String
    let email: String
    let first_name: String?
    let last_name: String?
    let birthday: String? // ISO date string from Django
}
