import Foundation

class UserService {
    private let userRepository = RealmUserRepository()
    
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
        } catch {
            // TODO: Log this
            print("❌ Failed to store user in Realm: \(error)")
        }
    }
    
    func getCurrentUser() -> UserObject? {
        guard let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int else {
            // TODO: Log this
            print("⚠️ No current user ID found in UserDefaults")
            return nil
        }
        
        let user = userRepository.load(serverId: currentUserId)
        return user
    }
    
    func updateUserName(firstName: String, lastName: String) {
        guard let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int else {
            return
        }
        
        do {
            try userRepository.setName(serverId: currentUserId, first: firstName, last: lastName)
        } catch {
            // TODO: Log this
            print("❌ Failed to update user name in Realm: \(error)")
        }
    }
    
    func updateUserBirthday(_ birthday: Date) {
        guard let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int else {
            return
        }
        
        do {
            try userRepository.setBirthday(serverId: currentUserId, date: birthday)
        } catch {
            // TODO: Log this
            print("❌ Failed to update user birthday in Realm: \(error)")
        }
    }
    
    func clearAllData() {
        do {
            try userRepository.clearAllData()
        } catch {
            print("❌ Failed to clear user data from Realm: \(error)")
        }
    }
}
