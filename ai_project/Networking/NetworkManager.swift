import Foundation
import Alamofire

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
                case .success(let user):
                    completion(.success(user))
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
    
    
    func uploadImage(data: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "http://localhost:8000/api/upload-image/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let uuidFilename = UUID().uuidString + ".jpg"

        let httpBody = createBody(boundary: boundary, data: data, mimeType: "image/jpeg", fieldName: "screenshot", filename: uuidFilename)
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "Upload failed", code: 1)))
                return
            }

            completion(.success(()))
        }.resume()
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
