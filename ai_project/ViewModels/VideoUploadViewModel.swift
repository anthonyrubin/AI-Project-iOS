import Foundation
import UIKit
import Combine

@MainActor
class VideoUploadViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
}

