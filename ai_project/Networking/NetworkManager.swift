import Foundation
import Alamofire
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "http://localhost:8000/api"

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
        
        guard let token = TokenManager.shared.getAccessToken() else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized: No token found."])))
            return
        }

        let url = "\(baseURL)/set-name/"
        let params = ["firstName": firstName, "lastName": lastName]

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]

        AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default, headers: headers)
            .validate(statusCode: 200..<300)        // 2xx only
            .response { resp in                     // no decoding
                switch resp.result {
                case .success:
                    print("switched success")
                    completion(.success(("")))
                case .failure(let err):
                    print("Switched failure")
                    // optional: inspect server error body
                    // let body = String(data: resp.data ?? Data(), encoding: .utf8)
                    completion(.failure(err))
                }
            }
    }

    func setBirthday(birthday: Date, completion: @escaping (Result<Void, AFError>) -> Void) {
        guard let token = TokenManager.shared.getAccessToken() else {
            completion(.failure(AFError.explicitlyCancelled))
            return
        }

        let url = "\(baseURL)/set-birthday/"
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        fmt.dateFormat = "yyyy-MM-dd"
        let params = ["birthday": fmt.string(from: birthday)]

        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]

        AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default, headers: headers)
            .validate(statusCode: 200..<300)
            .response { resp in
                switch resp.result {
                case .success: completion(.success(()))
                case .failure(let err): completion(.failure(err))
                }
            }
    }

    
    func uploadImage(data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = TokenManager.shared.getAccessToken() else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized: No token found."])))
            return
        }

        let url = "\(baseURL)/upload-image/" // Replace with your actual endpoint
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
        .responseJSON { response in
            switch response.result {
            case .success:
                completion(.success("Image uploaded successfully"))
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
