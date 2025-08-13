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

// MARK: - Video
final class VideoObject: Object {
    @Persisted(primaryKey: true) var serverId: Int
    @Persisted var s3Url: String = ""
    @Persisted var thumbnailUrl: String = ""
    @Persisted var originalFilename: String = ""
    @Persisted var fileSize: Int = 0
    @Persisted var duration: Double?
    @Persisted var uploadedAt: Date = Date()
    @Persisted var userServerId: Int
}

// MARK: - Analysis Event
final class AnalysisEventObject: Object {
    @Persisted(primaryKey: true) var id: ObjectId = ObjectId.generate()
    @Persisted var analysisServerId: Int
    @Persisted var timestamp: Double = 0.0
    @Persisted var label: String = ""
    @Persisted var feedback: String = ""
    @Persisted var metrics: List<AnalysisMetricObject>
    
    convenience init(analysisServerId: Int, event: AnalysisEvent) {
        self.init()
        self.analysisServerId = analysisServerId
        self.timestamp = event.t
        self.label = event.label
        self.feedback = event.feedback
        self.metrics = List<AnalysisMetricObject>()
        
        for metric in event.metrics {
            let metricObject = AnalysisMetricObject()
            metricObject.name = metric.name
            metricObject.value = metric.value
            metricObject.estimationMethod = metric.estimation_method
            self.metrics.append(metricObject)
        }
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
    @Persisted var userServerId: Int
    @Persisted var sport: String = ""
    @Persisted var sportCategory: String = ""
    @Persisted var professionalScore: Double?
    @Persisted var confidence: Double?
    @Persisted var clipSummary: String = ""
    @Persisted var overallTips: List<String>
    @Persisted var metricsCatalog: List<String>
    @Persisted var createdAt: Date = Date()
    @Persisted var events: List<AnalysisEventObject>
    
    // Computed property to get the video object
    var video: VideoObject? {
        let realm = try! RealmProvider.make()
        return realm.object(ofType: VideoObject.self, forPrimaryKey: videoServerId)
    }
    

    
    // MARK: - Helper Methods for UI
    
    /// Get all events sorted by timestamp
    var sortedEvents: [AnalysisEventObject] {
        return Array(events).sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Get events for a specific time range
    func eventsInRange(start: Double, end: Double) -> [AnalysisEventObject] {
        return Array(events).filter { $0.timestamp >= start && $0.timestamp <= end }
    }
    
    /// Get the first event (earliest timestamp)
    var firstEvent: AnalysisEventObject? {
        return sortedEvents.first
    }
    
    /// Get the last event (latest timestamp)
    var lastEvent: AnalysisEventObject? {
        return sortedEvents.last
    }
    
    /// Get overall tips as array
    var overallTipsArray: [String] {
        return Array(overallTips)
    }
    
    /// Get metrics catalog as array
    var metricsCatalogArray: [String] {
        return Array(metricsCatalog)
    }
}

// MARK: - Legacy Analysis (keeping for backward compatibility)
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
