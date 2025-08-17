import Foundation
import RealmSwift
import Combine

@MainActor
class LessonViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var analysis: VideoAnalysisObject
    @Published var errorMessage: String?
    @Published var analysisEvents: [AnalysisEventObject] = []
    @Published var videoUrl: String?
    @Published var isRefreshingUrl: Bool = false

    // MARK: - Dependencies
    private let repository: VideoAnalysisRepository

    // MARK: - Initialization
    init(analysis: VideoAnalysisObject, repository: VideoAnalysisRepository) {
        self.analysis = analysis
        self.repository = repository
        processAnalysisData()
    }
    
    // MARK: - Public Methods
    
    func getVideoUrl() {
        guard let video = analysis.video else {
            errorMessage = "No video data available"
            videoUrl = nil
            return
        }

        if video.isVideoUrlExpired {
            // URL is expired, request fresh URLs
            isRefreshingUrl = true
            refreshVideoUrl(for: video) { [weak self] success in
                Task { @MainActor in
                    self?.isRefreshingUrl = false
                    if success {
                        // URL has been refreshed, update the published property
                        self?.videoUrl = video.signedVideoUrl
                    } else {
                        self?.errorMessage = "Failed to refresh expired video URL"
                        self?.videoUrl = nil
                    }
                }
            }
        } else {
            // URL is still valid, set it immediately
            videoUrl = video.signedVideoUrl
        }
    }
    
    // MARK: - Table View Data Methods
    
    func getEventsCount() -> Int {
        return analysisEvents.count
    }
    
    func getEvent(at index: Int) -> AnalysisEventObject? {
        guard index >= 0 && index < analysisEvents.count else { return nil }
        return analysisEvents[index]
    }
    
    func getTableViewHeight() -> CGFloat {
        return CGFloat(analysisEvents.count * 80) // 80 is the cell height
    }
    
    func getAnalysisDataKeys() -> [String] {
        guard let analysisDataDict = analysis.analysisDataDict else { return [] }
        return Array(analysisDataDict.keys)
    }
    
    func getRawEventsCount() -> Int {
        guard let analysisDataDict = analysis.analysisDataDict,
              let events = analysisDataDict["events"] as? [[String: Any]] else { return 0 }
        return events.count
    }
    
    func getRawEvent(at index: Int) -> [String: Any]? {
        guard let analysisDataDict = analysis.analysisDataDict,
              let events = analysisDataDict["events"] as? [[String: Any]],
              index >= 0 && index < events.count else { return nil }
        return events[index]
    }
    
    // MARK: - Video Control Methods
    
    func seekToTimestamp(_ timestamp: Double) {
        // Convert Date to seconds for video seeking
        let timeInterval = Date(timeIntervalSince1970: timestamp).timeIntervalSince1970
        // This would be handled by the video player in the ViewController
        // The ViewModel can notify the ViewController to perform the seek
        NotificationCenter.default.post(
            name: .seekToTimestamp,
            object: nil,
            userInfo: ["timestamp": timeInterval]
        )
    }
    
    private func processAnalysisData() {
        // Process analysis events for display
        let events = analysis.events
        analysisEvents = Array(events).sorted { $0.timestamp < $1.timestamp }
    }
    
    private func refreshVideoUrl(for video: VideoObject, completion: @escaping (Bool) -> Void) {
        repository.refreshVideoUrl(videoId: video.serverId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedVideo):
                    if updatedVideo != nil {
                        completion(true)
                    } else {
                        completion(false)
                    }
                case .failure(let error):
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


