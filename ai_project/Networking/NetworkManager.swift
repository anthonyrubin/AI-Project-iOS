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
            completion(.failure(NetworkError.unauthorized))
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
        // If already refreshing, add to pending requests
        if isRefreshingToken {
            pendingRequests.append(completion)
            return
        }
        
        isRefreshingToken = true
        
        guard let refreshToken = TokenManager.shared.getRefreshToken() else {
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
                    // Convert TokenRefreshResponse to TokenResponse
                    let tokenData = TokenResponse(refresh: tokenResponse.refresh, access: tokenResponse.access)
                    
                    // Save new tokens
                    TokenManager.shared.saveTokens(tokenData)
                    
                    // Complete current request
                    completion(.success(()))
                    
                    // Complete all pending requests
                    self?.pendingRequests.forEach { $0(.success(())) }
                    self?.pendingRequests.removeAll()
                    
                case .failure(let error):
                    // Check if it's a 401 (refresh token expired)
                    if let statusCode = response.response?.statusCode, statusCode == 401 {
                        // Handle session expiration
                        AuthenticationManager.shared.handleSessionExpired()
                        
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
                    // optionally persist the user too
                    if let data = try? JSONEncoder().encode(payload.user) {
                        UserDefaults.standard.set(data, forKey: "currentUser")
                    }
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
    
    func uploadVideo(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
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
                completion(.success(uploadResponse.video_id))
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
    
    func analyzeVideo(videoId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = "\(baseURL)/analyze-video/"
        let params = ["video_id": videoId]

        performAuthenticatedRequest(
            url: url,
            method: .post,
            parameters: params,
            responseType: VideoAnalysisResponse.self
        ) { result in
            switch result {
            case .success(let analysisResponse):
                completion(.success(analysisResponse.analysis_id))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getUserAnalyses(completion: @escaping (Result<[VideoAnalysis], Error>) -> Void) {
        let url = "\(baseURL)/user-analyses/"

        performAuthenticatedRequest(
            url: url,
            method: .get,
            responseType: [VideoAnalysis].self
        ) { result in
            switch result {
            case .success(let analyses):
                completion(.success(analyses))
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
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
