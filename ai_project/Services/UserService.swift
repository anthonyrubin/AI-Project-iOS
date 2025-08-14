import Foundation

class UserService {
    static let shared = UserService()
    private let userRepository = RealmUserRepository()
    
    private init() {}
    
    // MARK: - User Management
    
    func storeUser(_ user: User) {
        do {
            // Parse birthday string to Date if available
            var birthdayDate: Date? = nil
            if let birthdayString = user.birthday {
                let dateFormatter = ISO8601DateFormatter()
                birthdayDate = dateFormatter.date(from: birthdayString)
            }
            
            let userDTO = UserDTO(
                id: user.id,
                username: user.username,
                email: user.email,
                firstName: user.first_name,
                lastName: user.last_name,
                birthday: birthdayDate
            )
            try userRepository.upsert(userDTO)
            print("✅ User stored in Realm: \(user.username)")
            print("   - firstName: \(user.first_name ?? "nil")")
            print("   - lastName: \(user.last_name ?? "nil")")
            print("   - birthday: \(user.birthday ?? "nil")")
        } catch {
            print("❌ Failed to store user in Realm: \(error)")
        }
    }
    
    func getCurrentUser() -> UserObject? {
        guard let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int else {
            print("⚠️ No current user ID found in UserDefaults")
            return nil
        }
        
        let user = userRepository.load(serverId: currentUserId)
        if user == nil {
            print("⚠️ User not found in Realm for ID: \(currentUserId)")
        } else {
            print("✅ Found user in Realm: \(user?.username ?? "unknown")")
        }
        return user
    }
    
    func updateUserName(firstName: String, lastName: String) {
        guard let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int else {
            print("⚠️ No current user ID found for name update")
            return
        }
        
        do {
            try userRepository.setName(serverId: currentUserId, first: firstName, last: lastName)
            print("✅ User name updated in Realm")
        } catch {
            print("❌ Failed to update user name in Realm: \(error)")
        }
    }
    
    func updateUserBirthday(_ birthday: Date) {
        guard let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int else {
            print("⚠️ No current user ID found for birthday update")
            return
        }
        
        do {
            try userRepository.setBirthday(serverId: currentUserId, date: birthday)
            print("✅ User birthday updated in Realm")
        } catch {
            print("❌ Failed to update user birthday in Realm: \(error)")
        }
    }
}
