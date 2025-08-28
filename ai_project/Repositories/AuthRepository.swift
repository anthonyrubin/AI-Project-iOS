import Alamofire
import Foundation

protocol AuthRepository {
    func logout(completion: @escaping () -> Void)
    func loginOrCheckpoint(
        username: String,
        password: String,
        completion: @escaping (Result<LoginOrCheckpointResponse, NetworkError>) -> Void
    )
    func verifyAccount(
        email: String,
        code: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    )
    
    func socialSignInWithData(
        provider: SocialLoginProviderType,
        data: [String: Any],
        completion: @escaping (Result<SocialSignInResponse, NetworkError>) -> Void
    )
}

class AuthRepositoryImpl: AuthRepository {
    func socialSignInWithData(
        provider: SocialLoginProviderType,
        data: [String: Any],
        completion: @escaping (Result<SocialSignInResponse, NetworkError>) -> Void
    ) {
        authAPI.socialSignInWithData(provider: provider, data: data) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                if let tokens = response.tokens {
                    self.tokenManager.saveTokens(tokens)
                }
                do {
                    try self.realmUserDataStore.upsert(user: response.user)
                    UserDefaults.standard.set(response.user.id, forKey: "currentUserId")
                } catch {
                    return completion(.failure(.cache(error)))
                }
                completion(.success(response))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    private let authAPI: AuthAPI
    private let tokenManager: TokenManager
    private let realmUserDataStore: UserDataStore
    
    init (
        authAPI: AuthAPI,
        tokenManager: TokenManager,
        realmUserDataStore: UserDataStore
    ) {
        self.authAPI = authAPI
        self.tokenManager = tokenManager
        self.realmUserDataStore = realmUserDataStore
    }
    
    func logout(completion: @escaping () -> Void) {

        // Refresh token is what the server needs. If missing, just do local logout.
        guard tokenManager.getRefreshToken() != nil else {
            tokenManager.clearTokens()
            completion()
            performLocalLogout()
            return
        }
        
        authAPI.logout(completion: { [weak self] in
            self?.tokenManager.clearTokens()
            completion()
            self?.performLocalLogout()
        })
    }
    
    func loginOrCheckpoint(
        username: String,
        password: String,
        completion: @escaping (Result<LoginOrCheckpointResponse, NetworkError>) -> Void
    ) {
        authAPI.loginOrCheckpoint(username: username, password: password) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let resp):
                if let t = resp.tokens { self.tokenManager.saveTokens(t) }
                do {
                    try self.realmUserDataStore.upsert(user: resp.user)
                    UserDefaults.standard.set(resp.user.id, forKey: "currentUserId")
                } catch {
                    return completion(.failure(.cache(error)))
                }
                completion(.success(resp))

            case .failure(let netErr):
                completion(.failure(netErr))
            }
        }
    }
    
    func verifyAccount(
        email: String,
        code: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        authAPI.verifyAccount(email: email, code: code) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let payload):
                self.tokenManager.saveTokens(payload.tokens)
                do {
                    try self.realmUserDataStore.upsert(user: payload.user)
                    UserDefaults.standard.set(payload.user.id, forKey: "currentUserId")
                    completion(.success(()))
                } catch {
                    completion(.failure(.cache(error)))
                }

            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    private func performLocalLogout() {
        // Clear user defaults
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        
        // Clear Realm cache
        do {
            try realmUserDataStore.clearAllData()
        } catch {
            //TODO: log here, this is critical
        }
        
        print("Posting .didlogout")
                
        // Post notification for app to handle
        NotificationCenter.default.post(name: .didLogout, object: nil)
    }
}
