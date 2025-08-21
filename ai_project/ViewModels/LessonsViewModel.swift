import Foundation
import RealmSwift
import Combine

@MainActor
class LessonsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var analyses: [VideoAnalysisObject] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRefreshing = false
    
    // MARK: - Dependencies
    private let repository: VideoAnalysisRepository
    private var notificationToken: NotificationToken?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(repository: VideoAnalysisRepository) {
        self.repository = repository
        setupRealmObservers()
    }
    
    deinit {
        notificationToken?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func loadAnalyses() {
        isLoading = true
        errorMessage = nil
        
        let realmAnalyses = repository.getAllAnalyses()
        analyses = Array(realmAnalyses)
        isLoading = false
    }
    
    func refreshAnalyses() {
        isRefreshing = true
        errorMessage = nil
        
        repository.fetchAndStoreNewAnalyses { [weak self] result in
            Task { @MainActor in
                self?.isRefreshing = false
                
                switch result {
                case .success(let newAnalyses):
                    print("✅ Fetched \(newAnalyses.count) new analyses")
                    // Realm observers will automatically update the UI
                case .failure(let error):
                    self?.errorMessage = "Failed to refresh analyses: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func getAnalysis(at index: Int) -> VideoAnalysisObject? {
        guard index >= 0 && index < analyses.count else { return nil }
        return analyses[index]
    }
    
    func getAnalysesCount() -> Int {
        return analyses.count
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
            analyses = Array(results)
        case .update(let results, _, _, _):
            analyses = Array(results)
        case .error(let error):
            errorMessage = "Data update error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    func hasError() -> Bool {
        return errorMessage != nil
    }
}
