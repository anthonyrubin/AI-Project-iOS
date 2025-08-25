import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var email: String = ""
    @Published var shouldNavigateToName: Bool = false
    @Published var shouldNavigateToBirthday: Bool = false
    @Published var shouldNavigateToHome: Bool = false
    
    // MARK: - Dependencies
    private let authRepository: AuthRepository
    private let socialLoginManager: SocialLoginManager
    
    // MARK: - Initialization
    init(
        authRepository: AuthRepository,
        socialLoginManager: SocialLoginManager
    ) {
        self.authRepository = authRepository
        self.socialLoginManager = socialLoginManager
    }
}
