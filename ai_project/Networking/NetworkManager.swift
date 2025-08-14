import Foundation
import Alamofire
import UIKit

// MARK: - Network Error Types
enum NetworkError: Error {
    case unauthorized
    case tokenRefreshFailed
    case noRefreshToken
    case refreshTokenExpired
    case requestFailed(Error)
    
    var localizedDescription: String {
        switch self {
        case .unauthorized:
            return "Unauthorized access"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        case .noRefreshToken:
            return "No refresh token available"
        case .refreshTokenExpired:
            return "Session expired. Please log in again."
        case .requestFailed(let error):
            return error.localizedDescription
        }
    }
}


class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "http://localhost:8000/api"
    
    // MARK: - Token Refresh Management
    private var isRefreshingToken = false
    private var pendingRequests: [(Result<Void, Error>) -> Void] = []
    
    // MARK: - Centralized Request Method with Auto-Refresh
    private func performAuthenticatedRequest<T: Codable>(
        url: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            print("❌ No access token available")
            let error = NetworkError.unauthorized
            showErrorModal(error)
            completion(.failure(error))
            return
        }
        
        print("🔐 Making authenticated request to: \(url)")
        
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
                    // Add debug logging for decoding errors
                    if let afError = error as? AFError {
                        switch afError {
                        case .responseSerializationFailed(let reason):
                            print("❌ Response serialization failed: \(reason)")
                            if case .decodingFailed(let decodingError) = reason {
                                print("❌ Decoding error: \(decodingError)")
                                // Log the raw response data
                                if let responseData = response.data {
                                    if let jsonString = String(data: responseData, encoding: .utf8) {
                                        print("📄 Raw JSON response: \(jsonString)")
                                    }
                                }
                            }
                        default:
                            print("❌ Other AFError: \(afError)")
                        }
                    }
                    
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
                                self?.showErrorModal(refreshError)
                                completion(.failure(refreshError))
                            }
                        }
                    } else {
                        completion(.failure(NetworkError.requestFailed(error)))
                    }
                }
            }
    }
    
    private func handleTokenRefresh(completion: @escaping (Result<Void, Error>) -> Void) {
        print("🔄 Starting token refresh")
        
        // If already refreshing, add to pending requests
        if isRefreshingToken {
            print("🔄 Token refresh already in progress, adding to pending requests")
            pendingRequests.append(completion)
            return
        }
        
        isRefreshingToken = true
        
        guard let refreshToken = TokenManager.shared.getRefreshToken() else {
            print("❌ No refresh token available")
            isRefreshingToken = false
            completion(.failure(NetworkError.noRefreshToken))
            return
        }
        
        print("🔄 Refresh token found, attempting refresh")
        
        let url = "\(baseURL)/token/refresh/"
        let params = ["refresh": refreshToken]
        
        print("🔄 Token refresh URL: \(url)")
        print("🔄 Refresh token: \(refreshToken.prefix(50))...")
        
        AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: TokenRefreshResponse.self) { [weak self] response in
                defer {
                    self?.isRefreshingToken = false
                }
                
                switch response.result {
                case .success(let tokenResponse):
                    print("✅ Token refresh successful")
                    // Convert TokenRefreshResponse to TokenResponse
                    let tokenData = TokenResponse(refresh: tokenResponse.refresh, access: tokenResponse.access)
                    
                    // Save new tokens
                    TokenManager.shared.saveTokens(tokenData)
                    print("💾 New tokens saved")
                    
                    // Complete current request
                    completion(.success(()))
                    
                    // Complete all pending requests
                    self?.pendingRequests.forEach { $0(.success(())) }
                    self?.pendingRequests.removeAll()
                    
                case .failure(let error):
                    print("❌ Token refresh failed: \(error)")
                    if let statusCode = response.response?.statusCode {
                        print("❌ HTTP status code: \(statusCode)")
                    }
                    
                    // Check if it's a 401 (refresh token expired)
                    if let statusCode = response.response?.statusCode, statusCode == 401 {
                        print("❌ Refresh token expired, handling session expiration")
                        // Handle session expiration
                        AuthenticationManager.shared.handleSessionExpired()
                        
                        // Complete current request with expired error
                        completion(.failure(NetworkError.refreshTokenExpired))
                        
                        // Complete all pending requests with expired error
                        self?.pendingRequests.forEach { $0(.failure(NetworkError.refreshTokenExpired)) }
                        self?.pendingRequests.removeAll()
                    } else {
                        print("❌ Other token refresh error")
                        // Other network error
                        completion(.failure(NetworkError.tokenRefreshFailed))
                        
                        // Complete all pending requests with error
                        self?.pendingRequests.forEach { $0(.failure(NetworkError.tokenRefreshFailed)) }
                        self?.pendingRequests.removeAll()
                    }
                }
            }
    }

    func loginOrCheckpoint(
        username: String,
        password: String,
        completion: @escaping (Result<LoginOrCheckpointResponse, AFError>) -> Void
    ) {
            let url = "\(baseURL)/login/"
            let params = ["username": username, "password": password]
            AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: LoginOrCheckpointResponse.self) { resp in
                    completion(resp.result)
                }
        }
    
    func logout(completion: @escaping () -> Void) {
        let url = "\(baseURL)/logout/"

        // Refresh token is what the server needs. If missing, just do local logout.
        guard let refresh = TokenManager.shared.getRefreshToken() else {
            completion()
            return
        }

        // Access header optional. Include if you have it; server doesn’t require it here.
        var headers: HTTPHeaders = [:]
        if let access = TokenManager.shared.getAccessToken() {
            headers.add(name: "Authorization", value: "Bearer \(access)")
        }

        AF.request(url,
                   method: .post,
                   parameters: ["refresh": refresh],
                   encoder: JSONParameterEncoder.default,
                   headers: headers)
        .validate(statusCode: 200..<300)   // server returns 204
        .response { _ in
            // Best-effort: regardless of network errors, proceed to local logout.
            completion()
        }
    }
    
    func createAccount(
        username: String,
        email: String,
        password1: String,
        password2: String,
        completion: @escaping (Result<Void, AFError>) -> Void
    ) {
        let url = "\(baseURL)/create-account/"
        let params = ["username": username, "email": email, "password1": password1, "password2": password2]

        AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)
            .validate(statusCode: 200..<300)        // 2xx only
            .response { resp in                     // no decoding
                switch resp.result {
                case .success:
                    print("switched success")
                    completion(.success(()))
                case .failure(let err):
                    print("Switched failure")
                    // optional: inspect server error body
                    // let body = String(data: resp.data ?? Data(), encoding: .utf8)
                    completion(.failure(err))
                }
            }
    }
    
    func verifyAccount(
        email: String,
        code: String,
        completion: @escaping (Result<Void, AFError>) -> Void
    ) {
        let url = "\(baseURL)/verify-account/"
        let params = ["email": email, "code": code]

        AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: VerifyAccountResponse.self) { resp in
                switch resp.result {
                case .success(let payload):
                    TokenManager.shared.saveTokens(payload.tokens)
                    // Store user ID and user data
                    UserDefaults.standard.set(payload.user.id, forKey: "currentUserId")
                    UserService.shared.storeUser(payload.user)
                    completion(.success(()))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
    }
    
    func setName(
        firstName: String,
        lastName: String,
        completion: @escaping (Result<String, Error>) -> Void
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
                completion(.success(""))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func setBirthday(birthday: Date, completion: @escaping (Result<Void, Error>) -> Void) {
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
            responseType: SetBirthdayResponse.self
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    
    func uploadImage(data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = TokenManager.shared.getAccessToken() else {
            completion(.failure(NetworkError.unauthorized))
            return
        }

        let url = "\(baseURL)/upload-image/"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]

        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(
                    data,
                    withName: "image",
                    fileName: "\(UUID().uuidString).jpg",
                    mimeType: "image/jpeg"
                )
            },
            to: url,
            headers: headers
        )
        .validate()
        .responseDecodable(of: UploadImageResponse.self) { [weak self] response in
            switch response.result {
            case .success(let uploadResponse):
                completion(.success(uploadResponse.message))
            case .failure(let error):
                // Check if it's an authentication error (401)
                if let statusCode = response.response?.statusCode, statusCode == 401 {
                    self?.handleTokenRefresh { refreshResult in
                        switch refreshResult {
                        case .success:
                            // Retry the upload with new token
                            self?.uploadImage(data: data, completion: completion)
                        case .failure(let refreshError):
                            completion(.failure(refreshError))
                        }
                    }
                } else {
                    completion(.failure(NetworkError.requestFailed(error)))
                }
            }
        }
    }
    
    func uploadVideo(fileURL: URL, completion: @escaping (Result<VideoUploadResponse, Error>) -> Void) {
        guard let token = TokenManager.shared.getAccessToken() else {
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
            },
            to: url,
            headers: headers
        )
        .validate()
        .responseDecodable(of: VideoUploadResponse.self) { [weak self] response in
            switch response.result {
            case .success(let uploadResponse):
                completion(.success(uploadResponse))
            case .failure(let error):
                // Check if it's an authentication error (401)
                if let statusCode = response.response?.statusCode, statusCode == 401 {
                    self?.handleTokenRefresh { refreshResult in
                        switch refreshResult {
                        case .success:
                            // Retry the upload with new token
                            self?.uploadVideo(fileURL: fileURL, completion: completion)
                        case .failure(let refreshError):
                            completion(.failure(refreshError))
                        }
                    }
                } else {
                    completion(.failure(NetworkError.requestFailed(error)))
                }
            }
        }
    }
    
    // analyzeVideo method removed - analysis now happens in uploadVideo
    
    func getUserAnalyses(lastSyncTimestamp: String? = nil, completion: @escaping (Result<DeltaSyncResponse, Error>) -> Void) {
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


    private func createBody(boundary: String, data: Data, mimeType: String, fieldName: String, filename: String) -> Data {
        var body = Data()

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        return body
    }
    
    // MARK: - Error Modal Display
    private func showErrorModal(_ error: Error) {
        // Get the top view controller to show the error modal
        if let topViewController = getTopViewController() {
            ErrorModalManager.shared.showError(error, from: topViewController)
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        var topViewController = window.rootViewController
        
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }
        
        if let navigationController = topViewController as? UINavigationController {
            topViewController = navigationController.visibleViewController
        }
        
        if let tabBarController = topViewController as? UITabBarController {
            topViewController = tabBarController.selectedViewController
        }
        
        return topViewController
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
