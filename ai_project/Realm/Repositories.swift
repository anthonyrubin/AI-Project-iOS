import Foundation
import RealmSwift

struct UserDTO: Codable {
    let id: Int
    let username: String
    let email: String
    let firstName: String?
    let lastName: String?
    let birthday: Date?
}

protocol UserRepository {
    func upsert(_ dto: UserDTO) throws
    func setName(serverId: Int, first: String, last: String) throws
    func setBirthday(serverId: Int, date: Date) throws
    func load(serverId: Int) -> UserObject?
}

protocol AnalysisRepository {
    func save(userServerId: Int, sport: String, score: Double, fps: Int, json: Data, videoPath: String?) throws
    func latest(for userServerId: Int) -> Results<AnalysisObject>
}

final class RealmUserRepository: UserRepository {
    func upsert(_ dto: UserDTO) throws {
        let realm = try RealmProvider.make()
        try realm.write {
            let obj = realm.object(ofType: UserObject.self, forPrimaryKey: dto.id) ?? UserObject()
            if obj.realm == nil { obj.serverId = dto.id; realm.add(obj, update: .modified) }
            obj.email = dto.email
            obj.username = dto.username
            obj.firstName = dto.firstName ?? ""
            obj.lastName = dto.lastName ?? ""
            obj.birthday = dto.birthday
            obj.updatedAt = Date()
        }
    }
    func setName(serverId: Int, first: String, last: String) throws {
        let realm = try RealmProvider.make()
        guard let obj = realm.object(ofType: UserObject.self, forPrimaryKey: serverId) else { return }
        try realm.write { obj.firstName = first; obj.lastName = last; obj.updatedAt = Date() }
    }
    func setBirthday(serverId: Int, date: Date) throws {
        let realm = try RealmProvider.make()
        guard let obj = realm.object(ofType: UserObject.self, forPrimaryKey: serverId) else { return }
        try realm.write { obj.birthday = date; obj.updatedAt = Date() }
    }
    func load(serverId: Int) -> UserObject? {
        (try? RealmProvider.make())?.object(ofType: UserObject.self, forPrimaryKey: serverId)
    }
}

final class RealmAnalysisRepository: AnalysisRepository {
    func save(userServerId: Int, sport: String, score: Double, fps: Int, json: Data, videoPath: String?) throws {
        let jsonURL = try FileStore.writeJSON(json)
        let realm = try RealmProvider.make()
        try realm.write {
            let obj = AnalysisObject()
            obj.userServerId = userServerId
            obj.sport = sport
            obj.score = score
            obj.fps = fps
            obj.jsonPath = jsonURL.path
            obj.videoPath = videoPath
            obj.createdAt = Date()
            realm.add(obj)
        }
    }
    func latest(for userServerId: Int) -> Results<AnalysisObject> {
        let realm = try! RealmProvider.make()
        return realm.objects(AnalysisObject.self)
            .where { $0.userServerId == userServerId }
            .sorted(byKeyPath: "createdAt", ascending: false)
    }
}

