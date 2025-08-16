import Foundation
import UIKit
import Combine

@MainActor
class VideoUploadViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var uploadedVideo: Video?
    @Published var shouldRefreshData = false
    
    // MARK: - Dependencies
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
    }
    
    func uploadVideo(fileURL: URL, on viewController: UIViewController) {
        isLoading = true
        errorMessage = nil
        uploadedVideo = nil
        shouldRefreshData = false
        
        // Show loading overlay
        let loadingOverlay = LoadingOverlay()
        loadingOverlay.show(on: viewController, message: "Analyzing")
        
        networkManager.uploadVideo(fileURL: fileURL) { [weak self] result in
            Task { @MainActor in
                loadingOverlay.hide()
                self?.isLoading = false
                
                switch result {
                case .success(let video):
                    self?.uploadedVideo = video
                    self?.shouldRefreshData = true
                    // Trigger data refresh in LessonsViewController
                    NotificationCenter.default.post(name: .videoAnalysisCompleted, object: nil)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    ErrorModalManager.shared.showError(error, from: viewController)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    func resetUploadState() {
        uploadedVideo = nil
        shouldRefreshData = false
    }
}

