import RealmSwift
import Foundation

enum RealmProvider {
    static func config() -> Realm.Configuration {
        Realm.Configuration(
            schemaVersion: 8,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 5 {
                    // Migrate from GCS URLs to signed URLs
                    migration.enumerateObjects(ofType: VideoObject.className()) { oldObject, newObject in
                        // Clear old GCS URL fields and set default signed URL fields
                        // The signed URLs will be populated when data is fetched from the backend
                        newObject!["signedVideoUrl"] = ""
                        newObject!["signedThumbnailUrl"] = ""
                        newObject!["videoExpiresAt"] = Date()
                        newObject!["thumbnailExpiresAt"] = Date()
                    }
                } else if oldSchemaVersion < 4 {
                    // Migrate from S3 URLs to GCS URLs (legacy migration)
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
