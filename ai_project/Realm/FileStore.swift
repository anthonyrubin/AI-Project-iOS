import Foundation

enum FileStore {
    static func appSupport() throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        if !fm.fileExists(atPath: base.path) { try fm.createDirectory(at: base, withIntermediateDirectories: true) }
        return base
    }
    static func writeJSON(_ data: Data, name: String = UUID().uuidString) throws -> URL {
        let url = try appSupport().appendingPathComponent("\(name).json")
        try data.write(to: url, options: .atomic)
        return url
    }
    static func removeFile(path: String) { try? FileManager.default.removeItem(atPath: path) }
}
