import Foundation
import Combine
import UIKit

@MainActor
class VideoAnalysisLoadingViewModel: ObservableObject {
    
    private let videoAnalysisRepository: VideoAnalysisRepository
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isUploadComplete = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        videoAnalysisRepository: VideoAnalysisRepository,
    ) {
        self.videoAnalysisRepository = videoAnalysisRepository
    }
    
    // MARK: - Public Methods
    
    func startVideoUpload(videoURL: URL) {
        isLoading = true
        errorMessage = nil
        isUploadComplete = false
    
        videoAnalysisRepository.uploadVideo(fileURL: videoURL) { [weak self] result in
            Task { @MainActor in
                self?.handleUploadResult(result)
            }
            
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    private func handleUploadResult(_ result: Result<Void, NetworkError>) {
        switch result {
        case .success(let _):
            isLoading = false
            isUploadComplete = true
            // Complete the progress to 100%
            //completeProgress()
            
        case .failure(let error):
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
