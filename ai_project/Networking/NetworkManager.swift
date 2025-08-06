import Foundation
import Alamofire
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "http://localhost:8000/api"

    func login(username: String, password: String, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        let url = "\(baseURL)/login/"
        let parameters = [
            "username": username,
            "password": password
        ]

        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
            .validate()
            .responseDecodable(of: TokenResponse.self) { response in
                switch response.result {
                case .success(let tokenResponse):
                    TokenManager.shared.saveTokens(tokenResponse)
                    completion(.success(tokenResponse))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    func createAccount(
        username: String,
        email: String,
        password1: String,
        password2: String,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        let url = "\(baseURL)/create-account/"
        let parameters = [
            "username": username,
            "email": email,
            "password1": password1,
            "password2": password2
        ]

        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
            .validate()
            .responseDecodable(of: User.self) { response in
                switch response.result {
                case .success(let user):
                    completion(.success(user))
                case .failure(let error):
                    completion(.failure(error))
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
