class BecomeAMemberViewModel {
    
    private var repository: VideoAnalysisRepository
    
    init(repository: VideoAnalysisRepository) {
        self.repository = repository
    }
    
    func getLastUpload() -> VideoAnalysisObject? {
        return repository.getLastAnalysis()
    }
}
