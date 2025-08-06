import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private init() {}

    func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete any existing item
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : true,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard
            status == errSecSuccess,
            let data = dataTypeRef as? Data,
            let result = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return result
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
