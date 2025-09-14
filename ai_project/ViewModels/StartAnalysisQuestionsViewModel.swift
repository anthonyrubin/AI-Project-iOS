import AVFoundation

@MainActor
class StartAnalysisQuestionsViewModel: ObservableObject {

    private let repository: VideoAnalysisRepository
    @Published var errorMessage: String?
    @Published var isUploadingVideo = false
    
    // MARK: - Initialization
    init(repository: VideoAnalysisRepository) {
        self.repository = repository
    }
    
    func startVideoUpload(fileURL: URL, liftType: String, uploadStateManager: UploadStateManager?) {
        
        let lift = Lift(rawValue: liftType)!.data().imagePrefix
        print("🚀 Starting video upload...")
        
        Task { @MainActor in
            isUploadingVideo = true
            errorMessage = nil
            print("📊 Upload state set to: isUploadingVideo=\(isUploadingVideo)")
        }
        
        repository.uploadVideo(fileURL: fileURL, liftType: lift) { [weak self] result in
            Task { @MainActor in
                print("✅ Upload completed, setting isUploadingVideo to false")
                self?.isUploadingVideo = false
                switch result {
                case .success():
                    self?.isUploadingVideo = false
                    uploadStateManager?.completeUpload()
                    // Trigger data refresh in LessonsViewController
                    NotificationCenter.default.post(name: .videoAnalysisCompleted, object: nil)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    uploadStateManager?.failUpload(with: error.localizedDescription)
                }
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
}
