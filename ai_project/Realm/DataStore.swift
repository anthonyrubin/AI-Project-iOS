import Foundation
import RealmSwift

struct UserDTO: Codable {
    let id: Int
    let appAccountToken: UUID
    let username: String
    let email: String
    let birthday: Date?
    let height: Double?
    let weight: Double?
    let isMetric: Bool?
    let workoutDaysPerWeek: String?
    let experience: String?
    let gender: String?
}

protocol UserDataStore {
    func upsert(user: User) throws
    func setBirthday(userId: Int, date: Date) throws
    func setExperience(userId: Int, experience: String) throws
    func setWorkoutDaysPerWeek(userId: Int, workoutDaysPerWeek: String) throws
    func setGender(userId: Int, gender: String) throws
    func setBodyMetrics(userId: Int, height: Double, weight: Double, isMetric: Bool) throws
    
    func load() -> UserObject?
    func clearAllData() throws
}

final class RealmUserDataStore: UserDataStore {

    func upsert(user: User) throws {
        
        var birthdayDate: Date? = nil
        if let birthdayString = user.birthday {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            birthdayDate = formatter.date(from: birthdayString)
        }
        
        let userDTO = UserDTO(
            id: user.id,
            appAccountToken: user.app_account_token,
            username: user.username,
            email: user.email,
            birthday: birthdayDate,
            height: user.height,
            weight: user.weight,
            isMetric: user.is_metric,
            workoutDaysPerWeek: user.workout_days_per_week,
            experience: user.experience,
            gender: user.gender
        )
        
        let realm = try RealmProvider.make()
        try realm.write {
            let obj = realm.object(ofType: UserObject.self, forPrimaryKey: userDTO.id) ?? UserObject()
            if obj.realm == nil { obj.serverId = userDTO.id; realm.add(obj, update: .modified) }
            obj.email = userDTO.email
            obj.username = userDTO.username
            obj.birthday = userDTO.birthday
            obj.height = userDTO.height
            obj.weight = userDTO.weight
            obj.isMetric = userDTO.isMetric
            obj.workoutDaysPerWeek = userDTO.workoutDaysPerWeek ?? ""
            obj.experience = userDTO.experience ?? ""
            obj.gender = userDTO.gender ?? ""
            obj.updatedAt = Date()
        }
    }

    func setBirthday(userId: Int, date: Date) throws {
        let realm = try RealmProvider.make()
        guard let obj = realm.object(ofType: UserObject.self, forPrimaryKey: userId) else { return }
        try realm.write { obj.birthday = date; obj.updatedAt = Date() }
    }
    
    func setExperience(userId: Int, experience: String) throws {
        let realm = try RealmProvider.make()
        guard let obj = realm.object(ofType: UserObject.self, forPrimaryKey: userId) else { return }
        try realm.write { obj.experience = experience; obj.updatedAt = Date() }
    }
    
    func setWorkoutDaysPerWeek(userId: Int, workoutDaysPerWeek: String) throws {
        let realm = try RealmProvider.make()
        guard let obj = realm.object(ofType: UserObject.self, forPrimaryKey: userId) else { return }
        try realm.write { obj.workoutDaysPerWeek = workoutDaysPerWeek; obj.updatedAt = Date() }
    }
    
    func setGender(userId: Int, gender: String) throws {
        let realm = try RealmProvider.make()
        guard let obj = realm.object(ofType: UserObject.self, forPrimaryKey: userId) else { return }
        try realm.write { obj.gender = gender; obj.updatedAt = Date() }
    }
    
    func setBodyMetrics(userId: Int, height: Double, weight: Double, isMetric: Bool) throws {
        let realm = try RealmProvider.make()
        guard let obj = realm.object(ofType: UserObject.self, forPrimaryKey: userId) else { return }
        try realm.write { obj.height = height; obj.weight = weight; obj.isMetric = isMetric; obj.updatedAt = Date() }
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

