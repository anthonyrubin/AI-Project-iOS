import Foundation
import RealmSwift
import Combine
import AVFoundation
import UIKit

@MainActor
class SessionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentUser: UserObject?
    @Published var userAnalyses: [VideoAnalysisObject] = []
    @Published var totalMinutesAnalyzed: Int = 0
    @Published var averageScore: Double = 0.0
    @Published var lastSession: VideoAnalysisObject?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var uploadedVideo: Bool?
    
    // MARK: - Video Upload State
    @Published var isUploadingVideo = false
    var uploadSnapshot: UIImage?
//    @Published var uploadProgress: Double = 0.0
    
    // MARK: - Dependencies
    private let userDataStore: UserDataStore
    private let repository: VideoAnalysisRepository
    private var notificationToken: NotificationToken?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        userDataStore: UserDataStore,
        repository: VideoAnalysisRepository,
    ) {
        self.userDataStore = userDataStore
        self.repository = repository
        setupRealmObservers()
        loadUserData()
    }
    
    deinit {
        notificationToken?.invalidate()
    }
    
    func uploadVideo(fileURL: URL) {
        // Capture snapshot first
        captureVideoSnapshot(from: fileURL) { [weak self] snapshot in
            Task { @MainActor in
                self?.uploadSnapshot = snapshot
                self?.startVideoUpload(fileURL: fileURL)
            }
        }
    }
    
    private func startVideoUpload(fileURL: URL) {
        print("🚀 Starting video upload...")
        
        Task { @MainActor in
            isUploadingVideo = true
            errorMessage = nil
            uploadedVideo = false
            
            print("📊 Upload state set to: isUploadingVideo=\(isUploadingVideo)")
        }
        
        repository.uploadVideo(fileURL: fileURL) { [weak self] result in
            Task { @MainActor in
                print("✅ Upload completed, setting isUploadingVideo to false")
                self?.isUploadingVideo = false
                
                switch result {
                case .success():
                    self?.isUploadingVideo = false
                    // Trigger data refresh in LessonsViewController
                    NotificationCenter.default.post(name: .videoAnalysisCompleted, object: nil)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func captureVideoSnapshot(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 300, height: 300) // Reasonable size for thumbnail
        
        // Try to get a frame at 1 second, fallback to 0.5 seconds if needed
        let time = CMTime(seconds: 1.0, preferredTimescale: 1)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, error in
            if let cgImage = cgImage {
                let image = UIImage(cgImage: cgImage)
                completion(image)
            } else {
                // Fallback: try at 0.5 seconds
                let fallbackTime = CMTime(seconds: 0.5, preferredTimescale: 1)
                imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: fallbackTime)]) { _, cgImage, _, _, _ in
                    if let cgImage = cgImage {
                        let image = UIImage(cgImage: cgImage)
                        completion(image)
                    } else {
                        // Final fallback: create a placeholder
                        let placeholder = self.createPlaceholderImage()
                        completion(placeholder)
                    }
                }
            }
        }
    }
    
    private func createPlaceholderImage() -> UIImage {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background gradient
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [
                                        UIColor.systemBlue.cgColor,
                                        UIColor.systemPurple.cgColor
                                    ] as CFArray,
                                    locations: [0, 1])!
            
            context.cgContext.drawLinearGradient(gradient,
                                               start: CGPoint(x: 0, y: 0),
                                               end: CGPoint(x: size.width, y: size.height),
                                               options: [])
            
            // Video icon
            let iconSize: CGFloat = 80
            let iconRect = CGRect(x: (size.width - iconSize) / 2,
                                y: (size.height - iconSize) / 2,
                                width: iconSize,
                                height: iconSize)
            
            if let videoIcon = UIImage(systemName: "video.fill") {
                videoIcon.withTintColor(.white, renderingMode: .alwaysOriginal)
                    .draw(in: iconRect)
            }
        }
    }
    
    // MARK: - Error Handling

    func resetUploadState() {
        uploadedVideo = false
        isUploadingVideo = false
        uploadSnapshot = nil
    }
    
    // MARK: - Public Methods
    
    func loadUserData() {
        isLoading = true
        errorMessage = nil
        
        currentUser = userDataStore.load()
        isLoading = false
    }
    
    func loadAnalyses() {
        isLoading = true
        errorMessage = nil
        
        let realmAnalyses = repository.getAllAnalyses()
        userAnalyses = Array(realmAnalyses)
        calculateStatistics()
        isLoading = false
    }
    
    func refreshData() {
        loadAnalyses()
    }
    
    func hasAnalyses() -> Bool {
        return !userAnalyses.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func setupRealmObservers() {
        let realmAnalyses = repository.getAllAnalyses()
        notificationToken = realmAnalyses.observe { [weak self] changes in
            Task { @MainActor in
                self?.handleRealmChanges(changes)
            }
        }
    }
    
    private func handleRealmChanges(_ changes: RealmCollectionChange<Results<VideoAnalysisObject>>) {
        switch changes {
        case .initial(let results):
            userAnalyses = Array(results)
            calculateStatistics()
        case .update(let results, _, _, _):
            userAnalyses = Array(results)
            calculateStatistics()
        case .error(let error):
            errorMessage = "Data update error: \(error.localizedDescription)"
        }
    }
    
    private func calculateStatistics() {
        // Calculate total minutes analyzed (month-to-date)
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let totalSeconds = userAnalyses
            .filter { $0.createdAt >= startOfMonth }
            .compactMap { $0.video?.durationSeconds }
            .reduce(0, +)
        
        // Round up to the nearest minute to include partial minutes
        totalMinutesAnalyzed = Int(ceil(Double(totalSeconds) / 60.0))
        
        // Calculate average professional score
        let scores = userAnalyses
            .filter { $0.createdAt >= startOfMonth }
            .compactMap { $0.professionalScore }
        
        if !scores.isEmpty {
            averageScore = scores.reduce(0, +) / Double(scores.count)
        } else {
            averageScore = 0.0
        }
        
        // Get the most recent analysis
        lastSession = userAnalyses
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}
