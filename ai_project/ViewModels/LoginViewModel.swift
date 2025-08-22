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

    func login(username: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        authRepository.loginOrCheckpoint(username: username, password: password) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.handleLoginResponse(response)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        
        socialLoginManager.signInWithGoogle { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let socialResult):
                    self?.handleSocialLogin(socialResult)
                case .failure(let error):
                    self?.isLoading = false
                    if case .cancelled = error {
                        // User cancelled, don't show error
                        return
                    }
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        socialLoginManager.signInWithApple { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let socialResult):
                    self?.handleSocialLogin(socialResult)
                case .failure(let error):
                    self?.isLoading = false
                    if case .cancelled = error {
                        // User cancelled, don't show error
                        return
                    }
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleSocialLogin(_ socialResult: SocialLoginResult) {
        switch socialResult.provider {
        case .google:
            authRepository.googleSignIn(
                idToken: socialResult.idToken,
                accessToken: socialResult.accessToken
            ) { [weak self] result in
                Task { @MainActor in
                    self?.isLoading = false
                    self?.handleSocialLoginResponse(result, socialResult: socialResult)
                }
            }
        case .apple:
            authRepository.appleSignIn(
                identityToken: socialResult.idToken,
                authorizationCode: nil,
                user: socialResult.user
            ) { [weak self] result in
                Task { @MainActor in
                    self?.isLoading = false
                    self?.handleSocialLoginResponse(result, socialResult: socialResult)
                }
            }
        }
    }
    
    private func handleSocialLoginResponse(_ result: Result<SocialSignInResponse, NetworkError>, socialResult: SocialLoginResult) {
        switch result {
        case .success(let response):
            if response.isNewUser {
                // New user - navigate to name setup
                shouldNavigateToName = true
            } else if let tokens = response.tokens {
                // Existing user with tokens - navigate to home
                shouldNavigateToHome = true
            } else if let checkpoint = response.checkpoint {
                // Handle checkpoint-based navigation
                handleCheckpoint(checkpoint)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleLoginResponse(_ response: LoginOrCheckpointResponse) {
        // Handle routing based on checkpoint
        switch response.checkpoint {
        case .verify_code:
            email = response.user.email
        case .name:
            shouldNavigateToName = true
        case .birthday:
            shouldNavigateToBirthday = true
        case .home:
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            shouldNavigateToHome = true
            NotificationCenter.default.post(name: .authDidSucceed, object: nil)
        }
    }
    
    private func handleCheckpoint(_ checkpoint: String) {
        switch checkpoint {
        case "name":
            shouldNavigateToName = true
        case "birthday":
            shouldNavigateToBirthday = true
        case "home":
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            shouldNavigateToHome = true
            NotificationCenter.default.post(name: .authDidSucceed, object: nil)
        default:
            errorMessage = "Unknown checkpoint: \(checkpoint)"
        }
    }
    
    // MARK: - Navigation Reset Methods
    
    func resetNavigationFlags() {
        email = ""
        shouldNavigateToName = false
        shouldNavigateToBirthday = false
        shouldNavigateToHome = false
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}
