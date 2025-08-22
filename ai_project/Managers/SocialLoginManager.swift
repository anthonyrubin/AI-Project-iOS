import Foundation
import AuthenticationServices
import GoogleSignIn
import Combine

// MARK: - Social Login Protocols

protocol SocialLoginProvider {
    func signIn(completion: @escaping (Result<SocialLoginResult, SocialLoginError>) -> Void)
    func signOut()
}

// MARK: - Social Login Models

struct SocialLoginResult {
    let provider: SocialLoginProviderType
    let idToken: String
    let accessToken: String?
    let user: String?
    let email: String?
    let name: String?
}

enum SocialLoginProviderType {
    case google
    case apple
}

enum SocialLoginError: Error, LocalizedError {
    case cancelled
    case failed(Error)
    case invalidCredentials
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Sign in was cancelled"
        case .failed(let error):
            return error.localizedDescription
        case .invalidCredentials:
            return "Invalid credentials"
        case .networkError:
            return "Network error occurred"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Social Login Manager

class SocialLoginManager: NSObject {
    
    // MARK: - Properties
    
    private let googleClientID: String
    private let appleClientID: String
    
    private var appleSignInCompletion: ((Result<SocialLoginResult, SocialLoginError>) -> Void)?
    
    // MARK: - Initialization
    
    init(googleClientID: String, appleClientID: String) {
        self.googleClientID = googleClientID
        self.appleClientID = appleClientID
        super.init()
        setupGoogleSignIn()
    }
    
    // MARK: - Setup
    
    private func setupGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("⚠️ GoogleService-Info.plist not found or CLIENT_ID missing")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle(completion: @escaping (Result<SocialLoginResult, SocialLoginError>) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = window.rootViewController else {
            completion(.failure(.unknown))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                if (error as NSError).code == GIDSignInError.canceled.rawValue {
                    completion(.failure(.cancelled))
                } else {
                    completion(.failure(.failed(error)))
                }
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(.invalidCredentials))
                return
            }
            
            let socialResult = SocialLoginResult(
                provider: .google,
                idToken: idToken,
                accessToken: user.accessToken.tokenString,
                user: user.userID,
                email: user.profile?.email,
                name: user.profile?.name
            )
            
            completion(.success(socialResult))
        }
    }
    
    func signOutFromGoogle() {
        GIDSignIn.sharedInstance.signOut()
    }
}

// MARK: - Apple Sign-In Extension

extension SocialLoginManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func signInWithApple(completion: @escaping (Result<SocialLoginResult, SocialLoginError>) -> Void) {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        
        // Store completion handler
        appleSignInCompletion = completion
        
        controller.performRequests()
    }
    
    func signOutFromApple() {
        // Apple doesn't provide a sign-out method
        // Just clear any stored credentials
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            appleSignInCompletion?(.failure(.invalidCredentials))
            return
        }
        
        let socialResult = SocialLoginResult(
            provider: .apple,
            idToken: tokenString,
            accessToken: nil,
            user: appleIDCredential.user,
            email: appleIDCredential.email,
            name: appleIDCredential.fullName?.formatted()
        )
        
        appleSignInCompletion?(.success(socialResult))
        appleSignInCompletion = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
            appleSignInCompletion?(.failure(.cancelled))
        } else {
            appleSignInCompletion?(.failure(.failed(error)))
        }
        appleSignInCompletion = nil
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            fatalError("No window found")
        }
        return window
    }
}

// MARK: - Extensions

extension PersonNameComponents {
    func formatted() -> String {
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .long
        return formatter.string(from: self)
    }
}
