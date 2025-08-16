import Foundation
import RealmSwift
import Combine

@MainActor
class LessonViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var analysis: VideoAnalysisObject
    @Published var errorMessage: String?
    @Published var analysisEvents: [LessonAnalysisEvent] = []
    
    // MARK: - Initialization
    init(analysis: VideoAnalysisObject) {
        self.analysis = analysis
        processAnalysisData()
    }
    
    // MARK: - Public Methods
    
    func getVideoUrl() -> String? {
        guard let video = analysis.video else {
            errorMessage = "No video data available"
            return nil
        }
        
        if video.isVideoUrlExpired {
            // URL is expired, request fresh URLs
            refreshExpiredUrls(for: video) { [weak self] success in
                if success {
                    // URL will be refreshed, but we can't return it from this async context
                    // The ViewController should handle this
                } else {
                    self?.errorMessage = "Failed to refresh expired video URL"
                }
            }
            return nil
        } else {
            return video.signedVideoUrl
        }
    }
    
    private func processAnalysisData() {
        // Process analysis events for display
        let events = analysis.events
        analysisEvents = Array(events).compactMap { event in
            // Convert AnalysisEventObject to LessonAnalysisEvent
            return LessonAnalysisEvent(
                timestamp: Date(timeIntervalSince1970: event.timestamp),
                eventType: event.label,
                description: event.feedback,
                confidence: 0.0 // AnalysisEventObject doesn't have confidence, using default
            )
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func refreshExpiredUrls(for video: VideoObject, completion: @escaping (Bool) -> Void) {
        VideoAnalysisRepository.shared.refreshExpiredUrls { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedVideos):
                    let wasUpdated = updatedVideos.contains { $0.serverId == video.serverId }
                    completion(wasUpdated)
                case .failure:
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Analysis Event Model
struct LessonAnalysisEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let eventType: String
    let description: String
    let confidence: Double
}
