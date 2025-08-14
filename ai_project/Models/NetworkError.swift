import Foundation

enum NetworkError: Error, LocalizedError {
    case unauthorized
    case tokenRefreshFailed
    case refreshTokenExpired
    case noRefreshToken
    case requestFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Authentication required. Please log in again."
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token. Please log in again."
        case .noRefreshToken:
            return "No refresh token available. Please log in again."
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .refreshTokenExpired:
            return "Refresh token expired. Please log in again."
        }
    }
}
