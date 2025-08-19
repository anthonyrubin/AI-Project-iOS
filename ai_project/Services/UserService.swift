import Foundation


protocol UserRepository {
    func storeUser()
}

class UserService {
    private let userRepository = RealmUserDataStore()
    
    // MARK: - User Management
    
//    func storeUser(_ user: User) {
//        do {
//            // Parse birthday string to Date if available
//
//            try userRepository.upsert(userDTO)
//        } catch {
//            // TODO: Log this
//            print("❌ Failed to store user in Realm: \(error)")
//        }
//    }
//    
    func getCurrentUser() -> UserObject? {        
        let user = userRepository.load()
        return user
    }
    
    func updateUserName(firstName: String, lastName: String) {
        guard let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int else {
            return
        }
        
        do {
            try userRepository.setName(userId: currentUserId, first: firstName, last: lastName)
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
            try userRepository.setBirthday(userId: currentUserId, date: birthday)
        } catch {
            // TODO: Log this
            print("❌ Failed to update user birthday in Realm: \(error)")
        }
    }
}
