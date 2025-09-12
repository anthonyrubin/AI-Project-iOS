import Foundation
import Combine
import UIKit

/// Manages upload state across the entire app using Combine publishers
@MainActor
class UploadStateManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether a video is currently being uploaded
    @Published var isUploading: Bool = false
    
    /// Upload progress (0.0 to 1.0)
    @Published var uploadProgress: Double = 0.0
    
    /// Upload error message, if any
    @Published var uploadError: String?
    
    /// Whether the upload completed successfully
    @Published var uploadCompleted: Bool = false
    
    /// Snapshot image of the video being uploaded
    @Published var uploadSnapshot: UIImage?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Start an upload process
    /// - Parameter snapshot: Optional snapshot image of the video being uploaded
    func startUpload(snapshot: UIImage? = nil) {
        isUploading = true
        uploadProgress = 0.0
        uploadError = nil
        uploadCompleted = false
        uploadSnapshot = snapshot
    }
    
    /// Update upload progress
    /// - Parameter progress: Progress value between 0.0 and 1.0
    func updateProgress(_ progress: Double) {
        uploadProgress = max(0.0, min(1.0, progress))
    }
    
    /// Complete the upload successfully
    func completeUpload() {
        isUploading = false
        uploadProgress = 1.0
        uploadError = nil
        uploadCompleted = true
        
        // Reset completion state after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.uploadCompleted = false
        }
    }
    
    /// Fail the upload with an error
    /// - Parameter error: Error message to display
    func failUpload(with error: String) {
        isUploading = false
        uploadProgress = 0.0
        uploadError = error
        uploadCompleted = false
    }
    
    /// Reset all upload state
    func resetUploadState() {
        isUploading = false
        uploadProgress = 0.0
        uploadError = nil
        uploadCompleted = false
        uploadSnapshot = nil
    }
    
    /// Clear any error state
    func clearError() {
        uploadError = nil
    }
}
