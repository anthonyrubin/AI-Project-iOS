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
    @Persisted var liftScore: Double?
    @Persisted var confidence: Double?
    @Persisted var overallAnalysis: String = ""
    @Persisted var metricsBreakdown: String = "" // JSON string of metrics breakdown
    @Persisted var overallTips: List<String> = List<String>()
    @Persisted var progressionDrills: List<String> = List<String>()
    @Persisted var metricsCatalog: List<String> = List<String>()
    @Persisted var createdAt: Date = Date()
    @Persisted var analysisData: String = "" // JSON string of analysis data
    @Persisted var icon: String = ""
    
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
    
    // Computed property to get parsed metrics breakdown
    var metricsBreakdownDict: [String: MetricBreakdown]? {
        guard !metricsBreakdown.isEmpty else { return nil }
        
        do {
            if let data = metricsBreakdown.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try decoder.decode([String: MetricBreakdown].self, from: data)
            }
        } catch {
            print("❌ Error parsing metrics breakdown: \(error)")
        }
        return nil
    }
    

    
    // MARK: - Helper Methods for UI
    
    /// Get overall tips as array
    var overallTipsArray: [String] {
        return Array(overallTips)
    }
    
    /// Get metrics catalog as array
    var metricsCatalogArray: [String] {
        return Array(metricsCatalog)
    }
    
    /// Get progression drills as array
    var progressionDrillsArray: [String] {
        return Array(progressionDrills)
    }
}
