import Foundation
import UIKit

class VideoUploadViewModel {
    
    var onUploadSuccess: ((String) -> Void)?
    var onUploadFailure: ((Error) -> Void)?
    var onAnalysisComplete: ((String) -> Void)?
    var onAnalysisFailure: ((Error) -> Void)?
    
    func uploadVideo(fileURL: URL) {
        NetworkManager.shared.uploadVideo(fileURL: fileURL) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let videoId):
                    self.onUploadSuccess?(videoId)
                    // After successful upload, trigger analysis
                    self.analyzeVideo(videoId: videoId)
                case .failure(let error):
                    self.onUploadFailure?(error)
                }
            }
        }
    }
    
    private func analyzeVideo(videoId: String) {
        NetworkManager.shared.analyzeVideo(videoId: videoId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let analysisId):
                    self.onAnalysisComplete?(analysisId)
                case .failure(let error):
                    self.onAnalysisFailure?(error)
                }
            }
        }
    }
}
