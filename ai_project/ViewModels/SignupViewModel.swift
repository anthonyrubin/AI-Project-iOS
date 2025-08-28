import Foundation
import Combine

@MainActor
class SignupViewModel: ObservableObject {
    
    private let authRepository: AuthRepository
    private let socialLoginManager: SocialLoginManager
    @Published var checkpoint: Checkpoint?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    init(
        authRepository: AuthRepository,
        socialLoginManager: SocialLoginManager
    ) {
        self.authRepository = authRepository
        self.socialLoginManager = socialLoginManager
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
        // For SignupViewController, this is always for existing users
        // (new users go through the signup flow and end up in CreateAccountViewController)
        sendSimpleSocialLogin(socialResult: socialResult)
    }
    
    private func sendSimpleSocialLogin(socialResult: SocialLoginResult) {
        // Simple request without signup data for existing users
        var requestData: [String: Any] = [
            "provider": socialResult.provider.rawValue,
            "id_token": socialResult.idToken
        ]
        
        // Add access token if available
        if let accessToken = socialResult.accessToken {
            requestData["access_token"] = accessToken
        }
        
        print("📝 SignupViewModel: Sending simple social login request for existing user")
        
        authRepository.socialSignInWithData(
            provider: socialResult.provider,
            data: requestData
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                self?.handleSocialLoginResponse(result, socialResult: socialResult)
            }
        }
    }
    
    private func handleSocialLoginResponse(_ result: Result<SocialSignInResponse, NetworkError>, socialResult: SocialLoginResult) {
        switch result {
        case .success(let response):
            if response.isNewUser {
                // New user - navigate to name setup
                checkpoint = .name
            } else if let _ = response.tokens {
                checkpoint = .home
            } else if let checkpoint = response.checkpoint {
                // Handle checkpoint-based navigation
                handleCheckpoint(checkpoint)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleCheckpoint(_ checkpoint: String) {
        let _checkpoint = Checkpoint(rawValue: checkpoint)
        switch _checkpoint {
        case .name, .birthday, .home:
            self.checkpoint = _checkpoint
        default:
            errorMessage = "Unknown checkpoint: \(checkpoint)"
        }
    }
    
    func resetNavigationFlags() {
        checkpoint = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
}
