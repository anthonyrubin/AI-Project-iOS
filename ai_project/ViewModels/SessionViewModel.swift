import Foundation
import RealmSwift
import Combine

@MainActor
class SessionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentUser: UserObject?
    @Published var userAnalyses: [VideoAnalysisObject] = []
    @Published var totalMinutesAnalyzed: Int = 0
    @Published var averageScore: Int = 0
    @Published var lastSession: VideoAnalysisObject?
    @Published var hasAnalyses: Bool = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
            updateAnalyses(Array(results))
        case .update(let results, let deletions, let insertions, let modifications):
            updateAnalyses(Array(results))
        case .error(let error):
            errorMessage = "Data update error: \(error.localizedDescription)"
        }
    }
    

    private func updateAnalyses(_ analyses: [VideoAnalysisObject]) {
        userAnalyses = analyses
        let validAnalyses = analyses.filter { !$0.deleted }
        hasAnalyses = !validAnalyses.isEmpty
        lastSession = validAnalyses.sorted { $0.createdAt > $1.createdAt }.first
        calculateStatistics()
    }
    
    private func calculateStatistics() {
        // Calculate total minutes analyzed (month-to-date)
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let totalSeconds = userAnalyses
            .filter { $0.createdAt >= startOfMonth && !$0.deleted }
            .compactMap { $0.video?.durationSeconds }
            .reduce(0, +)
        
        // Round up to the nearest minute to include partial minutes
        totalMinutesAnalyzed = Int(ceil(Double(totalSeconds) / 60.0))
        
        // Calculate average professional score
        let scores = userAnalyses
            .filter { $0.createdAt >= startOfMonth && !$0.deleted }
            .compactMap { $0.liftScore }
        
        if !scores.isEmpty {
            averageScore = scores.reduce(0, +) / scores.count
        } else {
            averageScore = 0
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}
