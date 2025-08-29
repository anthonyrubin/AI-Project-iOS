import Foundation
import UIKit

// MARK: - Signup Data Models
struct SignupUserData: Codable {
    // Basic Info

    var birthday: Date?
    var gender: String?
    
    // Physical Info
    var height: Double?
    var weight: Double?
    var isMetric: Bool?
    
    // Goals & Preferences
    var selectedGoals: [String]?
    var sportDisplay: String?
    
    // Video Analysis
    var didUploadVideoForAnalysis: Bool = false
    var videoAnalysisData: VideoAnalysisData?
    var videoURL: String? // Store as string path
    var videoSnapshotData: Data? // Store snapshot as Data
    
    // Social Login
    var socialLoginProvider: String? // "google" or "apple"
    var socialLoginToken: String?

    var currentStep: String?
    
    // Timestamps
    var signupStartedAt: Date?
    var lastUpdatedAt: Date?
}

struct VideoAnalysisData: Codable {
    var videoUrl: String?
    var thumbnailUrl: String?
    var analysisId: String?
    var uploadedAt: Date?
}

// MARK: - UserDefaultsManager
final class UserDefaultsManager {
    
    // MARK: - Singleton
    static let shared = UserDefaultsManager()
    private init() {}
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let signupData = "signup_user_data"
        static let isSignupInProgress = "is_signup_in_progress"
        static let signupSessionId = "signup_session_id"
    }
    
    // MARK: - Current Signup Data
    private var currentSignupData: SignupUserData {
        get {
            guard let data = UserDefaults.standard.data(forKey: Keys.signupData),
                  let signupData = try? JSONDecoder().decode(SignupUserData.self, from: data) else {
                return SignupUserData()
            }
            return signupData
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Keys.signupData)
            }
            
            guard let data = UserDefaults.standard.data(forKey: Keys.signupData),
                  let signupData = try? JSONDecoder().decode(SignupUserData.self, from: data) else {
                print("Guard failed")
                return
            }
            print("setting")
            print(data)
            print(signupData)
        }
    }
    
    // MARK: - Public Methods
    
    /// Start a new signup session
    func startSignupSession() {
        let sessionId = UUID().uuidString
        UserDefaults.standard.set(true, forKey: Keys.isSignupInProgress)
        UserDefaults.standard.set(sessionId, forKey: Keys.signupSessionId)
        
        var newData = SignupUserData()
        newData.signupStartedAt = Date()
        newData.lastUpdatedAt = Date()
        newData.currentStep = "started"
        
        currentSignupData = newData
        print("📝 UserDefaultsManager: Started new signup session: \(sessionId)")
    }
    
    /// Complete the signup session and clear data
    func completeSignupSession() {
        UserDefaults.standard.removeObject(forKey: Keys.signupData)
        UserDefaults.standard.set(false, forKey: Keys.isSignupInProgress)
        UserDefaults.standard.removeObject(forKey: Keys.signupSessionId)
    }
    
    /// Check if signup is in progress
    var isSignupInProgress: Bool {
        return UserDefaults.standard.bool(forKey: Keys.isSignupInProgress)
    }
    
    /// Get current signup session ID
    var signupSessionId: String? {
        return UserDefaults.standard.string(forKey: Keys.signupSessionId)
    }
    
    // MARK: - Data Update Methods
    
    /// Update basic user information
    func updateBasicInfo(firstName: String? = nil, lastName: String? = nil, birthday: Date? = nil, gender: String? = nil) {
        var data = currentSignupData
        if let birthday = birthday { data.birthday = birthday }
        if let gender = gender { data.gender = gender }
        data.lastUpdatedAt = Date()
        currentSignupData = data
        print("📝 UserDefaultsManager: Updated basic info")
    }
    
    /// Update physical information
    func updatePhysicalInfo(height: Double? = nil, weight: Double? = nil, isMetric: Bool? = nil) {
        var data = currentSignupData
        if let height = height { data.height = height }
        if let weight = weight { data.weight = weight }
        if let isMetric = isMetric { data.isMetric = isMetric }
        data.lastUpdatedAt = Date()
        currentSignupData = data
        print("📝 UserDefaultsManager: Updated physical info")
    }
    
    /// Update goals and preferences
    func updateGoals(selectedGoals: [String]? = nil, sportDisplay: String? = nil) {
        var data = currentSignupData
        if let selectedGoals = selectedGoals { data.selectedGoals = selectedGoals }
        if let sportDisplay = sportDisplay { data.sportDisplay = sportDisplay }
        data.lastUpdatedAt = Date()
        currentSignupData = data
        print("📝 UserDefaultsManager: Updated goals")
    }
    
    /// Update social login information
    func updateSocialLogin(provider: String, token: String) {
        var data = currentSignupData
        data.socialLoginProvider = provider
        data.socialLoginToken = token
        data.lastUpdatedAt = Date()
        currentSignupData = data
        print("📝 UserDefaultsManager: Updated social login - \(provider)")
    }
    
    /// Update video analysis information
    func updateVideoAnalysis(didUpload: Bool, videoData: VideoAnalysisData? = nil, videoURL: URL? = nil, videoSnapshot: UIImage? = nil) {
        var data = currentSignupData
        data.didUploadVideoForAnalysis = didUpload
        if let videoData = videoData { data.videoAnalysisData = videoData }
        if let videoURL = videoURL { data.videoURL = videoURL.path }
        if let videoSnapshot = videoSnapshot { 
            data.videoSnapshotData = videoSnapshot.jpegData(compressionQuality: 0.8)
        }
        data.lastUpdatedAt = Date()
        currentSignupData = data
        print("📝 UserDefaultsManager: Updated video analysis - uploaded: \(didUpload)")
    }
    
    /// Update signup progress
    func updateProgress(progress: Double, step: String) {
        var data = currentSignupData
        data.currentStep = step
        data.lastUpdatedAt = Date()
        currentSignupData = data
        print("📝 UserDefaultsManager: Updated progress to \(progress) at step: \(step)")
    }
    
    // MARK: - Data Retrieval Methods
    
    /// Get all current signup data
    func getSignupData() -> SignupUserData {
        return currentSignupData
    }
    
    /// Get video URL and snapshot for analysis
    func getVideoData() -> (videoURL: URL?, videoSnapshot: UIImage?) {
        let data = currentSignupData
        let url = data.videoURL.flatMap { URL(fileURLWithPath: $0) }
        let snapshot = data.videoSnapshotData.flatMap { UIImage(data: $0) }
        return (videoURL: url, videoSnapshot: snapshot)
    }
    
    /// Get specific data fields

    func getBirthday() -> Date? { return currentSignupData.birthday }
    func getGender() -> String? { return currentSignupData.gender }
    func getHeight() -> Double? { return currentSignupData.height }
    func getWeight() -> Double? { return currentSignupData.weight }
    func getIsMetric() -> Bool? { return currentSignupData.isMetric }
    func getSelectedGoals() -> [String]? { return currentSignupData.selectedGoals }
    func getSportDisplay() -> String? { return currentSignupData.sportDisplay }
    func getDidUploadVideo() -> Bool { return currentSignupData.didUploadVideoForAnalysis }
    func getVideoAnalysisData() -> VideoAnalysisData? { return currentSignupData.videoAnalysisData }
    func getSocialLoginProvider() -> String? { return currentSignupData.socialLoginProvider }
    func getSocialLoginToken() -> String? { return currentSignupData.socialLoginToken }
    
    // MARK: - Validation Methods
    
    /// Check if all required fields are filled for account creation
    func isReadyForAccountCreation() -> Bool {
        let data = currentSignupData
        return data.birthday != nil &&
               data.gender != nil &&
               data.height != nil &&
               data.weight != nil &&
               data.selectedGoals != nil &&
               data.sportDisplay != nil
    }
    
    /// Get missing required fields
    func getMissingRequiredFields() -> [String] {
        let data = currentSignupData
        var missing: [String] = []

        if data.birthday == nil { missing.append("Birthday") }
        if data.gender == nil { missing.append("Gender") }
        if data.height == nil { missing.append("Height") }
        if data.weight == nil { missing.append("Weight") }
        if data.selectedGoals == nil { missing.append("Goals") }
        if data.sportDisplay == nil { missing.append("Sport") }
        
        return missing
    }
    
    // MARK: - Debug Methods
    
    /// Print current signup data for debugging
    func debugPrintSignupData() {
        let data = currentSignupData
        print("🔍 UserDefaultsManager Debug:")
        print("  - Session ID: \(signupSessionId ?? "none")")
        print("  - Current Step: \(data.currentStep ?? "none")")
        print("  - Birthday: \(data.birthday?.description ?? "nil")")
        print("  - Gender: \(data.gender ?? "nil")")
        print("  - Height: \(data.height ?? 0)")
        print("  - Weight: \(data.weight ?? 0)")
        print("  - Is Metric: \(data.isMetric ?? false)")
        print("  - Goals: \(data.selectedGoals?.joined(separator: ", ") ?? "nil")")
        print("  - Sport: \(data.sportDisplay ?? "nil")")
        print("  - Did Upload Video: \(data.didUploadVideoForAnalysis)")
        print("  - Social Login: \(data.socialLoginProvider ?? "none")")
        print("  - Ready for Account Creation: \(isReadyForAccountCreation())")
    }
}
