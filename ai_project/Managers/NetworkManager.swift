import Foundation
import Alamofire
import UIKit

protocol AuthAPI {
    func loginOrCheckpoint(
        username: String,
        password: String,
        completion: @escaping (Result<LoginOrCheckpointResponse, NetworkError>) -> Void
    )
    func logout(completion: @escaping () -> Void)
    func verifyAccount(
        email: String,
        code: String,
        completion: @escaping (Result<VerifyAccountResponse, NetworkError>) -> Void
    )
    
    func socialSignInWithData(
        provider: SocialLoginProviderType,
        data: [String: Any],
        completion: @escaping (Result<SocialSignInResponse, NetworkError>) -> Void
    )
}

protocol SignupAPI {
    func createAccount(
        username: String,
        email: String,
        password1: String,
        password2: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    )
    
    func setName(
        firstName: String,
        lastName: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    )

    func setBirthday(birthday: Date, completion: @escaping (Result<Void, NetworkError>) -> Void)
}

protocol AnalysisAPI {
    func uploadVideo(fileURL: URL, liftType: String, completion: @escaping (Result<VideoAnalysis, NetworkError>) -> Void)
    func getUserAnalyses(lastSyncTimestamp: String?, completion: @escaping (Result<DeltaSyncResponse, NetworkError>) -> Void)
    func refreshSignedUrls(videoIds: [Int], completion: @escaping (Result<UrlRefreshResponse, Error>) -> Void)
}

protocol MembershipAPI {
    func attachSubscription(
        payload: AttachPayload,
        completion: @escaping (Result<AttachSubscriptionResponse, NetworkError>) -> Void
    )
    func checkAnalysisAllowance(
        completion: @escaping (Result<AnalysisAllowanceResponse, NetworkError>) -> Void
    )
    func restorePurchase(
        completion: @escaping (Result<RestorePurchaseResponse, NetworkError>) -> Void
    )
    func checkMembershipStatus(
        completion: @escaping (Result<MembershipStatusResponse, NetworkError>) -> Void
    )
}

class NetworkManager: AuthAPI, SignupAPI, AnalysisAPI, MembershipAPI {

    init(
        tokenManager: TokenManager
    ) {
        self.tokenManager = tokenManager
    }
    
    var onSessionExpired: (() -> Void)?
    
    private var tokenManager: TokenManager
    
    private let baseURL = "https://d734af29d0ef.ngrok-free.app/api"
    //private let baseURL = "http://localhost:8000/api"
    
    // MARK: - Token Refresh Management
    private var isRefreshingToken = false
    private var pendingRequests: [(Result<Void, Error>) -> Void] = []
    
    // MARK: - Centralized Request Method with Auto-Refresh
    private func performAuthenticatedRequest<T: Codable>(
        url: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        guard let token = tokenManager.getAccessToken() else {
            completion(.failure(.unauthorized))
            return
        }

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]

        AF.request(url, method: method, parameters: parameters, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: responseType) { [weak self] response in
                switch response.result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    // Check if it's an authentication error (401)
                    if let statusCode = response.response?.statusCode, statusCode == 401 {
                        self?.handleTokenRefresh { refreshResult in
                            switch refreshResult {
                            case .success:
                                // Retry the original request with new token
                                self?.performAuthenticatedRequest(
                                    url: url,
                                    method: method,
                                    parameters: parameters,
                                    responseType: responseType,
                                    completion: completion
                                )
                            case .failure(let refreshError):
                                completion(.failure(.tokenRefreshFailed))
                            }
                        }
                    } else {
                        // Try to parse the new standardized error format
                        if let data = response.data,
                           let apiErrorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                            completion(.failure(NetworkError.apiError(apiErrorResponse.error)))
                        } else {
                            completion(.failure(NetworkError.requestFailed(error)))
                        }
                    }
                }
            }
    }
    

    
    private func handleTokenRefresh(completion: @escaping (Result<Void, Error>) -> Void) {
        // If already refreshing, add to pending requests
        if isRefreshingToken {
            pendingRequests.append(completion)
            return
        }
        
        isRefreshingToken = true
        
        guard let refreshToken = tokenManager.getRefreshToken() else {
            isRefreshingToken = false
            completion(.failure(NetworkError.noRefreshToken))
            return
        }
                
        let url = "\(baseURL)/token/refresh/"
        let params = ["refresh": refreshToken]
        
        AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: TokenRefreshResponse.self) { [weak self] response in
                defer {
                    self?.isRefreshingToken = false
                }
                
                switch response.result {
                case .success(let tokenResponse):
                    let tokenData = TokenResponse(access: tokenResponse.access, refresh: tokenResponse.refresh)
                    
                    // Save new tokens
                    self?.tokenManager.saveTokens(tokenData)
                    completion(.success(()))
                    
                    // Complete all pending requests
                    self?.pendingRequests.forEach { $0(.success(())) }
                    self?.pendingRequests.removeAll()
                    
                case .failure( _):
                    
                    // Check if it's a 401 (refresh token expired)
                    if let statusCode = response.response?.statusCode, statusCode == 401 {
                        // Handle session expiration
                        self?.handleSessionExpired()
                        
                        // Complete current request with expired error
                        completion(.failure(NetworkError.refreshTokenExpired))
                        
                        // Complete all pending requests with expired error
                        self?.pendingRequests.forEach { $0(.failure(NetworkError.refreshTokenExpired)) }
                        self?.pendingRequests.removeAll()
                    } else {
                        // Other network error
                        completion(.failure(NetworkError.tokenRefreshFailed))
                        
                        // Complete all pending requests with error
                        self?.pendingRequests.forEach { $0(.failure(NetworkError.tokenRefreshFailed)) }
                        self?.pendingRequests.removeAll()
                    }
                }
            }
    }
    
    func handleSessionExpired() {
        // Clear all stored data
        tokenManager.clearTokens()
        UserDefaults.standard.removeObject(forKey: "currentUser")
        
        // Notify app that session has expired
        DispatchQueue.main.async {
            self.onSessionExpired?()
        }
    }

    func loginOrCheckpoint(
        username: String,
        password: String,
        completion: @escaping (Result<LoginOrCheckpointResponse, NetworkError>) -> Void
    ) {
        let url = "\(baseURL)/login/"
        let params = ["username": username, "password": password]

        AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: LoginOrCheckpointResponse.self) { resp in
                switch resp.result {
                case .success(let value):
                    completion(.success(value))

                case .failure(let afErr):
                    if let data = resp.data,
                       let api = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                        completion(.failure(.apiError(api.error)))
                    } else {
                        completion(.failure(.requestFailed(afErr)))
                    }
                }
            }
    }

    func logout(completion: @escaping () -> Void) {
        let url = "\(baseURL)/logout/"

        // Refresh token is what the server needs. If missing, just do local logout.
        guard let refresh = tokenManager.getRefreshToken() else {
            tokenManager.clearTokens()
            completion()
            return
        }

        // Access header optional. Include if you have it; server doesn’t require it here.
        var headers: HTTPHeaders = [:]
        if let access = tokenManager.getAccessToken() {
            headers.add(name: "Authorization", value: "Bearer \(access)")
        }

        AF.request(url,
                   method: .post,
                   parameters: ["refresh": refresh],
                   encoder: JSONParameterEncoder.default,
                   headers: headers)
        .validate(statusCode: 200..<300)   // server returns 204
        .response { _ in
            completion()
        }
    }
    
    func verifyAccount(
        email: String,
        code: String,
        completion: @escaping (Result<VerifyAccountResponse, NetworkError>) -> Void
    ) {
        let url = "\(baseURL)/verify-account/"
        let params = ["email": email, "code": code]

        AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: VerifyAccountResponse.self) { resp in
                switch resp.result {
                case .success(let payload):
                    completion(.success(payload))
                case .failure(let afErr):
                    // centralize API error parsing here (not in repo)
                    if let data = resp.data,
                       let apiErr = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                        completion(.failure(NetworkError.apiError(apiErr.error)))
                    } else {
                        completion(.failure(NetworkError.requestFailed(afErr)))
                    }
                }
            }
    }
    
    func createAccount(
        username: String,
        email: String,
        password1: String,
        password2: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        let url = "\(baseURL)/create-account/"
        let params = ["username": username, "email": email, "password1": password1, "password2": password2]

        AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)
            .validate(statusCode: 200..<300)        // 2xx only
            .response { resp in                     // no decoding
                switch resp.result {
                case .success:
                    completion(.success(()))
                case .failure(let err):
                    // Try to parse the new standardized error format
                    if let data = resp.data,
                       let apiErrorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                        completion(.failure(NetworkError.apiError(apiErrorResponse.error)))
                    } else {
                        completion(.failure(NetworkError.requestFailed(err)))
                    }
                }
            }
    }
    
    func setName(
        firstName: String,
        lastName: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        let url = "\(baseURL)/set-name/"
        let params = ["firstName": firstName, "lastName": lastName]
        
        performAuthenticatedRequest(
            url: url,
            method: .post,
            parameters: params,
            responseType: SetNameResponse.self
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func setBirthday(birthday: Date, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        let url = "\(baseURL)/set-birthday/"
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        fmt.dateFormat = "yyyy-MM-dd"
        let params = ["birthday": fmt.string(from: birthday)]

        performAuthenticatedRequest(
            url: url,
            method: .post,
            parameters: params,
            responseType: EmptyResponse.self
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func uploadVideo(fileURL: URL, liftType: String, completion: @escaping (Result<VideoAnalysis, NetworkError>) -> Void) {
        guard let token = tokenManager.getAccessToken() else {
            completion(.failure(NetworkError.unauthorized))
            return
        }

        let url = "\(baseURL)/upload-video/"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]

        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(
                    fileURL,
                    withName: "video",
                    fileName: fileURL.lastPathComponent,
                    mimeType: "video/mp4"
                )
                multipartFormData.append(
                    liftType.data(using: .utf8) ?? Data(),
                    withName: "lift_type"
                )
            },
            to: url,
            headers: headers
        )
        .validate()
        .responseDecodable(of: VideoAnalysis.self) { [weak self] response in
            switch response.result {
            case .success(let analysis):
                completion(.success(analysis))
            case .failure(let error):
                // Check if it's an authentication error (401)
                if let statusCode = response.response?.statusCode, statusCode == 401 {
                    self?.handleTokenRefresh { refreshResult in
                        switch refreshResult {
                        case .success:
                            // Retry the upload with new token
                            self?.uploadVideo(fileURL: fileURL, liftType: liftType, completion: completion)
                        case .failure(_):
                            completion(.failure(.tokenRefreshFailed))
                        }
                    }
                } else {
                    completion(.failure(NetworkError.requestFailed(error)))
                }
            }
        }
    }
    
    // analyzeVideo method removed - analysis now happens in uploadVideo
    
    func getUserAnalyses(lastSyncTimestamp: String? = nil, completion: @escaping (Result<DeltaSyncResponse, NetworkError>) -> Void) {
        var url = "\(baseURL)/user-analyses/"
        
        // Add last_sync parameter if provided
        if let lastSync = lastSyncTimestamp {
            url += "?last_sync=\(lastSync.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? lastSync)"
        }
        
        performAuthenticatedRequest(
            url: url,
            method: .get,
            responseType: DeltaSyncResponse.self
        ) { result in
            switch result {
            case .success(let deltaResponse):
                completion(.success(deltaResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func refreshSignedUrls(videoIds: [Int], completion: @escaping (Result<UrlRefreshResponse, Error>) -> Void) {
        let url = "\(baseURL)/refresh-urls/"
        let parameters: Parameters = ["video_ids": videoIds]
        
        performAuthenticatedRequest(
            url: url,
            method: .post,
            parameters: parameters,
            responseType: UrlRefreshResponse.self
        ) { result in
            switch result {
            case .success(let refreshResponse):
                completion(.success(refreshResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Unified Social Login
    
    func socialSignInWithData(
        provider: SocialLoginProviderType,
        data: [String: Any],
        completion: @escaping (Result<SocialSignInResponse, NetworkError>) -> Void
    ) {
        let url = "\(baseURL)/social-signin/"
        
        AF.request(url, method: .post, parameters: data, encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: SocialSignInResponse.self) { resp in
                switch resp.result {
                case .success(let response):
                    completion(.success(response))
                case .failure(let afErr):
                    if let data = resp.data,
                       let apiErr = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                        completion(.failure(NetworkError.apiError(apiErr.error)))
                    } else {
                        completion(.failure(NetworkError.requestFailed(afErr)))
                    }
                }
            }
    }
    
    // MARK: - MembershipAPI Implementation
    
    func attachSubscription(
        payload: AttachPayload,
        completion: @escaping (Result<AttachSubscriptionResponse, NetworkError>) -> Void
    ) {
        let url = "\(baseURL)/membership/attach-subscription/"
        let params: Parameters = [
            "product_id": payload.productId,
            "jws": payload.jws,
            "app_account_token": payload.appAccountToken ?? ""
        ]
        
        performAuthenticatedRequest(
            url: url,
            method: .post,
            parameters: params,
            responseType: AttachSubscriptionResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func checkAnalysisAllowance(
        completion: @escaping (Result<AnalysisAllowanceResponse, NetworkError>) -> Void
    ) {
        let url = "\(baseURL)/membership/analysis-allowance/"
        
        performAuthenticatedRequest(
            url: url,
            method: .get,
            responseType: AnalysisAllowanceResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func restorePurchase(
        completion: @escaping (Result<RestorePurchaseResponse, NetworkError>) -> Void
    ) {
        let url = "\(baseURL)/membership/restore-purchase/"
        
        performAuthenticatedRequest(
            url: url,
            method: .post,
            responseType: RestorePurchaseResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func checkMembershipStatus(
        completion: @escaping (Result<MembershipStatusResponse, NetworkError>) -> Void
    ) {
        let url = "\(baseURL)/membership/status/"
        
        performAuthenticatedRequest(
            url: url,
            method: .get,
            responseType: MembershipStatusResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
