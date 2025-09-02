class BecomeAMemberViewModel {
    
    private var repository: VideoAnalysisRepository
    
    init(repository: VideoAnalysisRepository) {
        self.repository = repository
    }
    
    func getLastUpload() -> VideoAnalysisObject? {
        return repository.getLastAnalysis()
    }
    
    func getEvents() -> [AnalysisEventObject] {
        
        if let events = getLastUpload()?.events {
            return Array(events).sorted { $0.timestamp < $1.timestamp }
        } else {
            return []
        }
    }
}
