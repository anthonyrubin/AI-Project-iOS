import Foundation

enum Checkpoint: String, Decodable { case verify_code, name, birthday, home }

struct LoginOrCheckpointResponse: Decodable {
    let checkpoint: Checkpoint
    let tokens: TokenResponse?
    let user: User
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

// MARK: - Social Login Models

struct GoogleSignInRequest: Codable {
    let idToken: String
    let accessToken: String?
    
    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
        case accessToken = "access_token"
    }
}

struct AppleSignInRequest: Codable {
    let identityToken: String
    let authorizationCode: String?
    let user: String? // Apple's user identifier
    
    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case authorizationCode = "authorization_code"
        case user
    }
}

struct SocialSignInResponse: Codable {
    let isNewUser: Bool
    let user: User
    let tokens: TokenResponse?
    let checkpoint: String?
    
    enum CodingKeys: String, CodingKey {
        case isNewUser = "is_new_user"
        case user
        case tokens
        case checkpoint
    }
}

struct TokenResponse: Codable {
    let access: String
    let refresh: String
}
