import Foundation

struct User: Codable {
    let id: Int
    let app_account_token: UUID
    let username: String
    let email: String
    let first_name: String?
    let last_name: String?
    let birthday: String? // ISO date string from Django
    let height: Double?
    let weight: Double?
    let is_metric: Bool
    let workout_days_per_week: String? // String from Django
    let experience: String?
    let gender: String?
}
