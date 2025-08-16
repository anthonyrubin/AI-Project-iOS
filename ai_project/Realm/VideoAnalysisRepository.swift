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
    static let shared = VideoAnalysisRepository()
    private init() {}
    
    // MARK: - Fetch and Store Methods
    
    func fetchAndStoreNewAnalyses(completion: @escaping (Result<[VideoAnalysisObject], Error>) -> Void) {
        // Get the last sync timestamp

        let lastSyncTimestamp = getLastSyncTimestamp()
        
        NetworkManager.shared.getUserAnalyses(lastSyncTimestamp: lastSyncTimestamp) { [weak self] result in
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
                        let dateFormatter = ISO8601DateFormatter()
                        if let videoExpiresAt = dateFormatter.date(from: analysis.video.videoExpiresAt) {
                            videoObject.videoExpiresAt = videoExpiresAt
                        }
                        if let thumbnailExpiresAt = dateFormatter.date(from: analysis.video.thumbnailExpiresAt) {
                            videoObject.thumbnailExpiresAt = thumbnailExpiresAt
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
                        analysisObject.userServerId = analysis.id // This should be the actual user ID
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
                        print("📊 Processing \(analysis.events?.count ?? 0) events for analysis \(analysis.id)")
                        if let events = analysis.events {
                            for (index, event) in events.enumerated() {
                                print("🔍 Processing event \(index + 1): \(event.label) at \(event.t)s")
                                do {
                                    let eventObject = AnalysisEventObject(analysisServerId: analysis.id, event: event)
                                    analysisObject.events.append(eventObject)
                                    print("✅ Successfully added event: \(event.label)")
                                } catch {
                                    print("❌ Failed to create event object: \(error)")
                                    // Continue with other events instead of failing completely
                                }
                            }
                            print("📊 Total events added to analysis object: \(analysisObject.events.count)")
                        } else {
                            print("⚠️ No events found in analysis")
                        }
                        
                        // Store analysis data as JSON string
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: analysis.analysis_data.mapValues { $0.value })
                            if let jsonString = String(data: jsonData, encoding: .utf8) {
                                analysisObject.analysisData = jsonString
                            }
                        } catch {
                            print("⚠️ Failed to serialize analysis data: \(error)")
                        }
                        
                        realm.add(analysisObject, update: .modified)
                        print("📊 Analysis object added to Realm with \(analysisObject.events.count) events")
                        storedObjects.append(analysisObject)
                    } catch {
                        // Continue with other analyses instead of failing completely
                        print("❌ Failed to process analysis \(analysis.id): \(error)")
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
            print("❌ Error accessing Realm in getAllAnalyses: \(error)")
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
    
    func refreshExpiredUrls(completion: @escaping (Result<[VideoObject], Error>) -> Void) {
        do {
            let realm = try RealmProvider.make()
            
            // Get all videos and manually check for expired URLs
            let allVideos = realm.objects(VideoObject.self)
            print("🔍 Total videos in Realm: \(allVideos.count)")
            
            let expiredVideos = allVideos.filter { video in
                let videoExpired = video.isVideoUrlExpired
                let thumbnailExpired = video.isThumbnailUrlExpired
                let currentTime = Date()
                print("🔍 Video \(video.serverId):")
                print("   - Video expires at: \(video.videoExpiresAt)")
                print("   - Thumbnail expires at: \(video.thumbnailExpiresAt)")
                print("   - Current time: \(currentTime)")
                print("   - Video expired: \(videoExpired)")
                print("   - Thumbnail expired: \(thumbnailExpired)")
                return videoExpired || thumbnailExpired
            }
            
            print("🔍 Expired videos found: \(expiredVideos.count)")
            
            if expiredVideos.isEmpty {
                print("🔍 No expired videos found, returning empty array")
                completion(.success([]))
                return
            }
            
            let videoIds = Array(expiredVideos.map { $0.serverId })
            print("🔍 Video IDs to refresh: \(videoIds)")
            
            // Call backend to refresh URLs
            NetworkManager.shared.refreshSignedUrls(videoIds: videoIds) { [weak self] result in
                switch result {
                case .success(let refreshResponse):
                    print("🔍 Received refresh response with \(refreshResponse.refreshed_urls.count) URLs")
                    self?.updateVideosWithRefreshedUrls(refreshResponse.refreshed_urls, completion: completion)
                case .failure(let error):
                    print("❌ Failed to refresh URLs: \(error)")
                    completion(.failure(error))
                }
            }
            
        } catch {
            print("❌ Error in refreshExpiredUrls: \(error)")
            completion(.failure(error))
        }
    }
    
    private func updateVideosWithRefreshedUrls(_ refreshedUrls: [RefreshedUrl], completion: @escaping (Result<[VideoObject], Error>) -> Void) {
        do {
            let realm = try RealmProvider.make()
            let dateFormatter = ISO8601DateFormatter()
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
                    }
                }
            }
            
            completion(.success(updatedVideos))
            
        } catch {
            completion(.failure(error))
        }
    }
}


