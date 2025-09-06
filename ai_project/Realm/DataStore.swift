import Foundation
import RealmSwift

struct UserDTO: Codable {
    let id: Int
    let appAccountToken: UUID
    let username: String
    let email: String
    let firstName: String?
    let lastName: String?
    let birthday: Date?
}

protocol UserDataStore {
    func upsert(user: User) throws
    func setName(userId: Int, first: String, last: String) throws
    func setBirthday(userId: Int, date: Date) throws
    func load() -> UserObject?
    func clearAllData() throws
}

protocol AnalysisDataStore {
    func save(userServerId: Int, sport: String, score: Double, fps: Int, json: Data, videoPath: String?) throws
//    func latest(for userServerId: Int) -> Results<AnalysisObject>
}

final class RealmUserDataStore: UserDataStore {

    func upsert(user: User) throws {
        
        var birthdayDate: Date? = nil
        if let birthdayString = user.birthday {
            let dateFormatter = ISO8601DateFormatter()
            birthdayDate = dateFormatter.date(from: birthdayString)
        }
        
        let userDTO = UserDTO(
            id: user.id,
            appAccountToken: user.app_account_token,
            username: user.username,
            email: user.email,
            firstName: user.first_name,
            lastName: user.last_name,
            birthday: birthdayDate
        )
        
        let realm = try RealmProvider.make()
        try realm.write {
            let obj = realm.object(ofType: UserObject.self, forPrimaryKey: userDTO.id) ?? UserObject()
            if obj.realm == nil { obj.serverId = userDTO.id; realm.add(obj, update: .modified) }
            obj.email = userDTO.email
            obj.username = userDTO.username
            obj.firstName = userDTO.firstName ?? ""
            obj.lastName = userDTO.lastName ?? ""
            obj.birthday = userDTO.birthday
            obj.updatedAt = Date()
        }
    }

    func setName(userId: Int, first: String, last: String) throws {
        let realm = try RealmProvider.make()
        guard let obj = realm.object(ofType: UserObject.self, forPrimaryKey: userId) else { return }
        try realm.write { obj.firstName = first; obj.lastName = last; obj.updatedAt = Date() }
    }
    func setBirthday(userId: Int, date: Date) throws {
        let realm = try RealmProvider.make()
        guard let obj = realm.object(ofType: UserObject.self, forPrimaryKey: userId) else { return }
        try realm.write { obj.birthday = date; obj.updatedAt = Date() }
    }
    func load() -> UserObject? {
        guard let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int else {
            // TODO: Log this
            print("⚠️ No current user ID found in UserDefaults")
            return nil
        }

        return try? RealmProvider.make().object(ofType: UserObject.self, forPrimaryKey: currentUserId)
    }
    
    func clearAllData() throws {
        let realm = try RealmProvider.make()
        try realm.write {
            realm.deleteAll()
        }
    }
}

