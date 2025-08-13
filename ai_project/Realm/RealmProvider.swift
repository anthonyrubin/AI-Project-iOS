import RealmSwift

enum RealmProvider {
    static func config() -> Realm.Configuration {
        Realm.Configuration(
            schemaVersion: 2,
            migrationBlock: { _, _ in /* add rules when you bump versions */ }
        )
    }
    static func make() throws -> Realm { try Realm(configuration: config()) }
}
