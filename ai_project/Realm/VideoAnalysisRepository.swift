import Foundation
import RealmSwift

class VideoAnalysisRepository {
    static let shared = VideoAnalysisRepository()
    private init() {}
    
    // MARK: - Fetch and Store Methods
    
    func fetchAndStoreNewAnalyses(completion: @escaping (Result<[VideoAnalysisObject], Error>) -> Void) {
        // Get the latest analysis timestamp from local storage
        let latestTimestamp = getLatestAnalysisTimestamp()
        
        NetworkManager.shared.getUserAnalyses { [weak self] result in
            switch result {
            case .success(let analyses):
                self?.storeNewAnalyses(analyses, since: latestTimestamp, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func storeNewAnalyses(_ analyses: [VideoAnalysis], since timestamp: Date?, completion: @escaping (Result<[VideoAnalysisObject], Error>) -> Void) {
        do {
            let realm = try RealmProvider.make()
            
            // Filter new analyses
            let newAnalyses = analyses.filter { analysis in
                guard let timestamp = timestamp else { return true }
                let analysisDate = ISO8601DateFormatter().date(from: analysis.created_at) ?? Date()
                return analysisDate > timestamp
            }
            
            var storedObjects: [VideoAnalysisObject] = []
            
            try realm.write {
                for analysis in newAnalyses {
                    // Store video first
                    let videoObject = VideoObject()
                    videoObject.serverId = analysis.video.id
                    videoObject.s3Url = analysis.video.s3_url
                    videoObject.thumbnailUrl = analysis.video.thumbnail_url ?? analysis.video.s3_url.replacingOccurrences(of: ".mp4", with: "_thumb.jpg")
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
                    analysisObject.createdAt = ISO8601DateFormatter().date(from: analysis.created_at) ?? Date()
                    
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
                        for event in events {
                            let eventObject = AnalysisEventObject(analysisServerId: analysis.id, event: event)
                            analysisObject.events.append(eventObject)
                        }
                    }
                    
                    realm.add(analysisObject, update: .modified)
                    storedObjects.append(analysisObject)
                }
            }
            
            completion(.success(storedObjects))
            
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Local Data Access
    
    func getAllAnalyses() -> Results<VideoAnalysisObject> {
        let realm = try! RealmProvider.make()
        return realm.objects(VideoAnalysisObject.self).sorted(byKeyPath: "createdAt", ascending: false)
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
    
    func clearAllData() {
        do {
            let realm = try RealmProvider.make()
            try realm.write {
                realm.delete(realm.objects(VideoAnalysisObject.self))
                realm.delete(realm.objects(VideoObject.self))
            }
        } catch {
            print("Error clearing data: \(error)")
        }
    }
}
