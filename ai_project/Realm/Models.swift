import RealmSwift
import Foundation

// MARK: - User
final class UserObject: Object {
    @Persisted(primaryKey: true) var serverId: Int      // your backend user id
    @Persisted var appAccountToken: UUID
    @Persisted var email: String = ""
    @Persisted var username: String = ""
    @Persisted var firstName: String = ""
    @Persisted var lastName: String = ""
    @Persisted var birthday: Date?                      // optional
    @Persisted var height: Double?                      // height in centimeters
    @Persisted var weight: Double?                      // weight in kilograms
    @Persisted var isMetric: Bool = false               // whether user prefers metric units
    @Persisted var workoutDaysPerWeek: String = "" // workout days as string
    @Persisted var experience: String = ""              // user's experience level
    @Persisted var gender: String = ""
    @Persisted var createdAt: Date = Date()
    @Persisted var updatedAt: Date = Date()
}

// MARK: - Video
final class VideoObject: Object {
    @Persisted(primaryKey: true) var serverId: Int
    @Persisted var signedVideoUrl: String = ""
    @Persisted var signedThumbnailUrl: String = ""
    @Persisted var videoExpiresAt: Date = Date()
    @Persisted var thumbnailExpiresAt: Date = Date()
    @Persisted var originalFilename: String = ""
    @Persisted var fileSize: Int = 0
    @Persisted var duration: Double?
    @Persisted var uploadedAt: Date = Date()
    @Persisted var userServerId: Int
    
    // MARK: - Helper Methods
    
    /// Check if video URL is expired
    var isVideoUrlExpired: Bool {
        return Date() >= videoExpiresAt
    }
    
    /// Check if thumbnail URL is expired
    var isThumbnailUrlExpired: Bool {
        return Date() >= thumbnailExpiresAt
    }
    
    /// Check if any URL is expired
    var hasExpiredUrls: Bool {
        return isVideoUrlExpired || isThumbnailUrlExpired
    }
    
    /// Get formatted duration string (e.g., "2:30" for 2 minutes 30 seconds)
    var formattedDuration: String {
        guard let duration = duration else { return "Unknown" }
        
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "0:%02d", seconds)
        }
    }
    
    /// Get duration in seconds
    var durationSeconds: Int {
        return Int(duration ?? 0)
    }
    
    /// Check if duration is available
    var hasDuration: Bool {
        return duration != nil && duration! > 0
    }
}

// MARK: - Analysis Metric
final class AnalysisMetricObject: EmbeddedObject {
    @Persisted var name: String = ""
    @Persisted var value: String = ""
    @Persisted var estimationMethod: String = ""
}

// MARK: - Video Analysis
final class VideoAnalysisObject: Object {
    @Persisted(primaryKey: true) var serverId: Int
    @Persisted var videoServerId: Int
    @Persisted var userId: Int
    @Persisted var sport: String = ""
    @Persisted var sportCategory: String = ""
    @Persisted var liftScore: Int?
    @Persisted var confidence: Double?
    @Persisted var overallAnalysis: String = ""
    @Persisted var strengths: String = "" // JSON string of strengths
    @Persisted var areasForImprovement: String = "" // JSON string of areas for improvement
    @Persisted var createdAt: Date = Date()
    @Persisted var analysisData: String = "" // JSON string of analysis data
    @Persisted var icon: String = ""
    @Persisted var deleted: Bool = false
    
    // Computed property to get the video object
    var video: VideoObject? {
        do {
            let realm = try RealmProvider.make()
            return realm.object(ofType: VideoObject.self, forPrimaryKey: videoServerId)
        } catch {
            return nil
        }
    }
    
    // Computed property to get parsed analysis data
    var analysisDataDict: [String: Any]? {
        guard !analysisData.isEmpty else { return nil }
        
        do {
            if let data = analysisData.data(using: .utf8) {
                return try JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
        } catch {
            print("❌ Error parsing analysis data: \(error)")
        }
        return nil
    }
    
    // Computed property to get parsed strengths
    var strengthsArray: [Strength]? {
        guard !strengths.isEmpty else { return nil }
        
        do {
            if let data = strengths.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try decoder.decode([Strength].self, from: data)
            }
        } catch {
            print("❌ Error parsing strengths: \(error)")
        }
        return nil
    }
    
    // Computed property to get parsed areas for improvement
    var areasForImprovementArray: [AreaForImprovement]? {
        guard !areasForImprovement.isEmpty else { return nil }
        
        do {
            if let data = areasForImprovement.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try decoder.decode([AreaForImprovement].self, from: data)
            }
        } catch {
            print("❌ Error parsing areas for improvement: \(error)")
        }
        return nil
    }
}
