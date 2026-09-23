import Foundation

public enum PhotoStore {
    public static func stem(from photoId: String) -> String {
        (photoId as NSString).deletingPathExtension
    }

    public static func isSeedPhoto(_ photoId: String?) -> Bool {
        guard let photoId else { return false }
        let s = stem(from: photoId)
        return SeedData.photoBasenames.contains(photoId)
            || SeedData.photoBasenames.contains { stem(from: $0) == s }
    }

    public static var photosDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("TimeKeeper/WatchPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public static func userPhotoURL(photoId: String) -> URL {
        photosDirectory.appendingPathComponent(photoId)
    }

    @discardableResult
    public static func saveUserPhoto(data: Data) throws -> String {
        let name = "\(UUID().uuidString).jpg"
        try data.write(to: userPhotoURL(photoId: name), options: .atomic)
        return name
    }

    public static func deleteUserPhoto(photoId: String?) {
        guard let photoId, !isSeedPhoto(photoId) else { return }
        try? FileManager.default.removeItem(at: userPhotoURL(photoId: photoId))
    }

    public static func loadData(photoId: String?) -> Data? {
        guard let photoId, !photoId.isEmpty else { return nil }
        let userURL = userPhotoURL(photoId: photoId)
        if FileManager.default.fileExists(atPath: userURL.path),
           let data = try? Data(contentsOf: userURL) {
            return data
        }
        let name = stem(from: photoId)
        let ext = (photoId as NSString).pathExtension
        let extOrJpg = ext.isEmpty ? "jpg" : ext
        var bundles: [Bundle] = [.main]
        #if SWIFT_PACKAGE
        bundles.insert(.module, at: 0)
        #endif
        for bundle in bundles {
            let candidates: [URL?] = [
                bundle.url(forResource: name, withExtension: extOrJpg, subdirectory: "SeedPhotos"),
                bundle.url(forResource: name, withExtension: extOrJpg, subdirectory: "Resources/SeedPhotos"),
                bundle.url(forResource: name, withExtension: extOrJpg),
                bundle.url(forResource: photoId, withExtension: nil, subdirectory: "SeedPhotos")
            ]
            for case let url? in candidates {
                if let data = try? Data(contentsOf: url) { return data }
            }
        }
        return nil
    }
}
