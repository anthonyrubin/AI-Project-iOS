import RealmSwift

enum RealmProvider {
    static func config() -> Realm.Configuration {
        Realm.Configuration(
            schemaVersion: 4,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 {
                    // Migrate from S3 URLs to GCS URLs
                    migration.enumerateObjects(ofType: VideoObject.className()) { oldObject, newObject in
                        // Rename s3Url to gcsUrl
                        if let oldS3Url = oldObject!["s3Url"] as? String {
                            newObject!["gcsUrl"] = oldS3Url
                        }
                        
                        // Rename thumbnailUrl to thumbnailGcsUrl
                        if let oldThumbnailUrl = oldObject!["thumbnailUrl"] as? String {
                            newObject!["thumbnailGcsUrl"] = oldThumbnailUrl
                        }
                    }
                }
            }
        )
    }
    static func make() throws -> Realm { try Realm(configuration: config()) }
}
