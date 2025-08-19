import Foundation
import RealmSwift

// Extension to make DateFormatter configuration easier
extension DateFormatter {
    func then(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self)
        return self
    }
}

class VideoAnalysisRepository {
    private var networkManager: NetworkManager
    
    init (networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    // MARK: - Fetch and Store Methods
    
    func fetchAndStoreNewAnalyses(completion: @escaping (Result<[VideoAnalysisObject], Error>) -> Void) {
        // Get the last sync timestamp

        let lastSyncTimestamp = getLastSyncTimestamp()
        
        networkManager.getUserAnalyses(lastSyncTimestamp: lastSyncTimestamp) { [weak self] result in
            switch result {
            case .success(let deltaResponse):
                // Store the new sync timestamp
                self?.storeLastSyncTimestamp(deltaResponse.sync_timestamp)
                
                // Store the new analyses
                self?.storeNewAnalyses(deltaResponse.analyses, since: nil, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func storeNewAnalyses(_ analyses: [VideoAnalysis], since timestamp: Date?, completion: @escaping (Result<[VideoAnalysisObject], Error>) -> Void) {
        do {
            let realm = try RealmProvider.make()
            
            // With delta sync, all returned analyses are new/changed
            let newAnalyses = analyses
            
            var storedObjects: [VideoAnalysisObject] = []
            
            try realm.write {
                for analysis in newAnalyses {
                    do {
                        // Store video first
                        let videoObject = VideoObject()
                        videoObject.serverId = analysis.video.id
                        videoObject.signedVideoUrl = analysis.video.signedVideoUrl
                        videoObject.signedThumbnailUrl = analysis.video.signedThumbnailUrl
                        
                        // Parse expiration dates
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                        dateFormatter.timeZone = TimeZone.current
                        
                        if let videoExpiresAt = dateFormatter.date(from: analysis.video.videoExpiresAt) {
                            videoObject.videoExpiresAt = videoExpiresAt
                        } else {
                            // TODO: Log here
                        }
                        
                        if let thumbnailExpiresAt = dateFormatter.date(from: analysis.video.thumbnailExpiresAt) {
                            videoObject.thumbnailExpiresAt = thumbnailExpiresAt
                        } else {
                            // TODO: Log here
                        }
                        
                        videoObject.originalFilename = analysis.video.original_filename
                        videoObject.fileSize = analysis.video.file_size
                        videoObject.duration = analysis.video.duration
                        videoObject.uploadedAt = ISO8601DateFormatter().date(from: analysis.video.uploaded_at) ?? Date()
                        videoObject.userServerId = analysis.video.id // This should be the user ID, not video ID
                        
                        realm.add(videoObject, update: .modified)
                        
                        // Store analysis using the new structured approach
                        let analysisObject = VideoAnalysisObject()
                        analysisObject.serverId = analysis.id
                        analysisObject.videoServerId = analysis.video.id
                        analysisObject.userId = analysis.id // This should be the actual user ID
                        analysisObject.sport = analysis.sport
                        analysisObject.sportCategory = analysis.sport_category
                        analysisObject.professionalScore = analysis.professional_score
                        analysisObject.confidence = analysis.confidence
                        analysisObject.clipSummary = analysis.clip_summary
                        
                        // Parse timestamp
                        if let parsedDate = dateFormatter.date(from: analysis.created_at) {
                            analysisObject.createdAt = parsedDate
                        } else {
                            // Try alternative date formats
                            let alternativeFormatters = [
                                DateFormatter().then { $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'" },
                                DateFormatter().then { $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'" },
                                DateFormatter().then { $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" },
                                DateFormatter().then { $0.dateFormat = "yyyy-MM-dd HH:mm:ss" }
                            ]
                            
                            var foundDate: Date?
                            for formatter in alternativeFormatters {
                                if let date = formatter.date(from: analysis.created_at) {
                                    foundDate = date
                                    break
                                }
                            }
                            
                            if let foundDate = foundDate {
                                analysisObject.createdAt = foundDate
                            } else {
                                // Only use current date as last resort
                                analysisObject.createdAt = Date()
                            }
                        }
                        
                        // Add overall tips
                        for tip in analysis.overall_tips {
                            analysisObject.overallTips.append(tip)
                        }
                        
                        // Add metrics catalog
                        for metric in analysis.metrics_catalog {
                            analysisObject.metricsCatalog.append(metric)
                        }
                        
                        // Add events if available
                        if let events = analysis.events {
                            for (index, event) in events.enumerated() {
                                let eventObject = AnalysisEventObject(analysisServerId: analysis.id, event: event)
                                analysisObject.events.append(eventObject)
                            }
                        }
                        
                        // Store analysis data as JSON string
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: analysis.analysis_data.mapValues { $0.value })
                            if let jsonString = String(data: jsonData, encoding: .utf8) {
                                analysisObject.analysisData = jsonString
                            }
                        } catch {
                            // TODO: Log this
                            print("⚠️ Failed to serialize analysis data: \(error)")
                        }
                        
                        realm.add(analysisObject, update: .modified)
                        storedObjects.append(analysisObject)
                    }
                }
            }
            
            completion(.success(storedObjects))
            
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Local Data Access
    
    func getAllAnalyses() -> Results<VideoAnalysisObject> {
        do {
            let realm = try RealmProvider.make()
            return realm.objects(VideoAnalysisObject.self).sorted(byKeyPath: "createdAt", ascending: false)
        } catch {
            // Return empty results instead of crashing
            let realm = try! RealmProvider.make()
            return realm.objects(VideoAnalysisObject.self).filter("serverId == -1") // Empty results
        }
    }
    
    func getAnalysis(by serverId: Int) -> VideoAnalysisObject? {
        let realm = try! RealmProvider.make()
        return realm.object(ofType: VideoAnalysisObject.self, forPrimaryKey: serverId)
    }
    
    func getVideo(by serverId: Int) -> VideoObject? {
        let realm = try! RealmProvider.make()
        return realm.object(ofType: VideoObject.self, forPrimaryKey: serverId)
    }
    
    // MARK: - Helper Methods
    
    private func getLatestAnalysisTimestamp() -> Date? {
        let realm = try! RealmProvider.make()
        let latestAnalysis = realm.objects(VideoAnalysisObject.self)
            .sorted(byKeyPath: "createdAt", ascending: false)
            .first
        
        return latestAnalysis?.createdAt
    }
    
    // Get the last sync timestamp from UserDefaults
    private func getLastSyncTimestamp() -> String? {
        return UserDefaults.standard.string(forKey: "last_sync_timestamp")
    }
    
    // Store the last sync timestamp in UserDefaults
    private func storeLastSyncTimestamp(_ timestamp: String) {
        UserDefaults.standard.set(timestamp, forKey: "last_sync_timestamp")
    }
    
    func clearAllData() {
        do {
            let realm = try RealmProvider.make()
            try realm.write {
                realm.delete(realm.objects(VideoAnalysisObject.self))
                realm.delete(realm.objects(VideoObject.self))
            }
            // Clear sync timestamp to force full refresh next time
            UserDefaults.standard.removeObject(forKey: "last_sync_timestamp")
        } catch {
            // TODO: Log this
            print("Error clearing data: \(error)")
        }
    }
    
    func forceFullSync(completion: @escaping (Result<[VideoAnalysisObject], Error>) -> Void) {
        // Clear sync timestamp to force full sync
        UserDefaults.standard.removeObject(forKey: "last_sync_timestamp")
        fetchAndStoreNewAnalyses(completion: completion)
    }
    
    // Clear sync timestamp (useful for testing or when user logs out)
    func clearSyncTimestamp() {
        UserDefaults.standard.removeObject(forKey: "last_sync_timestamp")
    }
    
    // MARK: - URL Refresh Methods
    
    /// Refreshes a single video URL - used for individual lesson views
    func refreshVideoUrl(videoId: Int, completion: @escaping (Result<VideoObject?, Error>) -> Void) {
        
        // Call backend to refresh this specific video
        networkManager.refreshSignedUrls(videoIds: [videoId]) { [weak self] result in
            switch result {
            case .success(let refreshResponse):
                self?.updateVideoWithRefreshedUrl(videoId: videoId, refreshResponse: refreshResponse, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func updateVideoWithRefreshedUrl(videoId: Int, refreshResponse: UrlRefreshResponse, completion: @escaping (Result<VideoObject?, Error>) -> Void) {
        do {
            let realm = try RealmProvider.make()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            dateFormatter.timeZone = TimeZone.current
            
            // Find the specific video in the response
            guard let refreshedUrl = refreshResponse.refreshed_urls.first(where: { $0.video_id == videoId }) else {
                completion(.success(nil))
                return
            }
            
            try realm.write {
                if let videoObject = realm.object(ofType: VideoObject.self, forPrimaryKey: videoId) {
                    print("🔄 Repository: Updating video \(videoId) with new URLs")
                    videoObject.signedVideoUrl = refreshedUrl.signed_video_url
                                            videoObject.signedThumbnailUrl = refreshedUrl.signed_thumbnail_url
                        
                        // Update expiration dates
                        if let videoExpiresAt = dateFormatter.date(from: refreshedUrl.video_expires_at) {
                            videoObject.videoExpiresAt = videoExpiresAt
                        }
                        
                        if let thumbnailExpiresAt = dateFormatter.date(from: refreshedUrl.thumbnail_expires_at) {
                            videoObject.thumbnailExpiresAt = thumbnailExpiresAt
                        }
                        
                        print("🔄 Repository: Successfully updated video \(videoId)")
                    completion(.success(videoObject))
                } else {
                    completion(.success(nil))
                }
            }
            
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Refreshes all expired video URLs - used for lessons list view
    func refreshExpiredUrls(completion: @escaping (Result<[VideoObject], Error>) -> Void) {
        do {
            let realm = try RealmProvider.make()
            
            // Get all videos and manually check for expired URLs
            let allVideos = realm.objects(VideoObject.self)
            
            let expiredVideos = allVideos.filter { video in
                let videoExpired = video.isVideoUrlExpired
                let thumbnailExpired = video.isThumbnailUrlExpired
                let currentTime = Date()
                return videoExpired || thumbnailExpired
            }
            
            if expiredVideos.isEmpty {
                completion(.success([]))
                return
            }
            
            let videoIds = Array(expiredVideos.map { $0.serverId })
            
            // Call backend to refresh URLs
            networkManager.refreshSignedUrls(videoIds: videoIds) { [weak self] result in
                switch result {
                case .success(let refreshResponse):
                    self?.updateVideosWithRefreshedUrls(
                        refreshResponse.refreshed_urls,
                        completion: completion
                    )
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
        } catch {
            completion(.failure(error))
        }
    }
    
    private func updateVideosWithRefreshedUrls(_ refreshedUrls: [RefreshedUrl], completion: @escaping (Result<[VideoObject], Error>) -> Void) {
        do {
            let realm = try RealmProvider.make()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            dateFormatter.timeZone = TimeZone.current
            var updatedVideos: [VideoObject] = []

            try realm.write {
                for refreshedUrl in refreshedUrls {
                    if let videoObject = realm.object(ofType: VideoObject.self, forPrimaryKey: refreshedUrl.video_id) {
                        videoObject.signedVideoUrl = refreshedUrl.signed_video_url
                        videoObject.signedThumbnailUrl = refreshedUrl.signed_thumbnail_url
                        
                        // Update expiration dates
                        if let videoExpiresAt = dateFormatter.date(from: refreshedUrl.video_expires_at) {
                            videoObject.videoExpiresAt = videoExpiresAt
                        }
                        
                        if let thumbnailExpiresAt = dateFormatter.date(from: refreshedUrl.thumbnail_expires_at) {
                            videoObject.thumbnailExpiresAt = thumbnailExpiresAt
                        }
                        
                        updatedVideos.append(videoObject)
                    } else {
                        // TODO: Log this
                        print("🔄 Repository: ❌ Could not find video object for ID \(refreshedUrl.video_id)")
                    }
                }
            }
            completion(.success(updatedVideos))
            
        } catch {
            completion(.failure(error))
        }
    }
    
}
