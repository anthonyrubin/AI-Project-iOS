class TokenManager {
    static let shared = TokenManager()
    private init() {}

    func saveTokens(_ tokenResponse: TokenResponse) {
        KeychainManager.shared.save(key: "accessToken", value: tokenResponse.access)
        KeychainManager.shared.save(key: "refreshToken", value: tokenResponse.refresh)
    }

    func getAccessToken() -> String? {
        return KeychainManager.shared.read(key: "accessToken")
    }

    func getRefreshToken() -> String? {
        return KeychainManager.shared.read(key: "refreshToken")
    }

    func clearTokens() {
        KeychainManager.shared.delete(key: "accessToken")
        KeychainManager.shared.delete(key: "refreshToken")
    }
}
