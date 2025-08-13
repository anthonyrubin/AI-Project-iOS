import RealmSwift
import Foundation

// MARK: - User
final class UserObject: Object {
    @Persisted(primaryKey: true) var serverId: Int      // your backend user id
    @Persisted var email: String = ""
    @Persisted var username: String = ""
    @Persisted var firstName: String = ""
    @Persisted var lastName: String = ""
    @Persisted var birthday: Date?                      // optional
    @Persisted var createdAt: Date = Date()
    @Persisted var updatedAt: Date = Date()
}

// MARK: - Analysis
final class AnalysisObject: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var userServerId: Int
    @Persisted var sport: String = ""
    @Persisted var score: Double = 0
    @Persisted var fps: Int = 8
    @Persisted var jsonPath: String = ""                // file path in app container
    @Persisted var videoPath: String?                   // optional
    @Persisted var createdAt: Date = Date()
}
