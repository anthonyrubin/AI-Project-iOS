import Foundation

// MARK: - API Error Response Models
struct APIErrorResponse: Codable {
    let error: APIError
}

struct APIError: Codable {
    let message: String
    let code: String
    let field: String?
}

// MARK: - Network Error Enum
enum NetworkError: Error, LocalizedError {
    case unauthorized
    case tokenRefreshFailed
    case refreshTokenExpired
    case noRefreshToken
    case requestFailed(Error)
    case apiError(APIError)
    case cache(Error)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Authentication required. Please log in again."
        case .tokenRefreshFailed:
            return "Session expired. Please log in again."
        case .noRefreshToken:
            return "No refresh token available. Please log in again."
        case .requestFailed(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .refreshTokenExpired:
            return "Refresh token expired. Please log in again."
        case .apiError(let apiError):
            return apiError.message
        case .cache(let error):
            return error.localizedDescription
        }
    }
    
    var failureReason: String? {
        switch self {
        case .apiError(let apiError):
            return apiError.code
        default:
            return nil
        }
    }
}
