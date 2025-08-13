import Foundation
import UIKit

class VideoUploadViewModel {
    
    var onUploadSuccess: ((String) -> Void)?
    var onUploadFailure: ((Error) -> Void)?
    var onAnalysisComplete: ((String) -> Void)?
    var onAnalysisFailure: ((Error) -> Void)?
    var onProgressUpdate: ((String) -> Void)?
    var onDataRefreshNeeded: (() -> Void)?
    
    private var loadingOverlay: LoadingOverlay?
    
    func uploadVideo(fileURL: URL, on viewController: UIViewController) {
        // Show loading overlay
        loadingOverlay = LoadingOverlay()
        loadingOverlay?.show(on: viewController, message: "Uploading video...")
        
        NetworkManager.shared.uploadVideo(fileURL: fileURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let videoId):
                    self?.onUploadSuccess?(videoId)
                    self?.loadingOverlay?.updateMessage("Analyzing video...")
                    // After successful upload, trigger analysis
                    self?.analyzeVideo(videoId: videoId)
                case .failure(let error):
                    self?.loadingOverlay?.hide()
                    self?.onUploadFailure?(error)
                }
            }
        }
    }
    
    private func analyzeVideo(videoId: String) {
        NetworkManager.shared.analyzeVideo(videoId: videoId) { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingOverlay?.hide()
                
                switch result {
                case .success(let analysisId):
                    self?.onAnalysisComplete?(analysisId)
                    // Trigger data refresh in LessonsViewController
                    self?.onDataRefreshNeeded?()
                case .failure(let error):
                    self?.onAnalysisFailure?(error)
                }
            }
        }
    }
}
