import Foundation
import SwiftData

public enum Persistence {
    public static let schema = Schema([Watch.self])

    /// Local-first store. CloudKit is proposed later but not enabled.
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let config = ModelConfiguration(
            "TimeKeeper",
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    @MainActor
    public static func previewContainer() -> ModelContainer {
        do {
            let container = try makeContainer(inMemory: true)
            _ = try SeedData.seedIfEmpty(into: container.mainContext)
            return container
        } catch {
            fatalError("Preview ModelContainer failed: \(error)")
        }
    }

    public static func makeCloudKitContainerPlaceholder() throws -> ModelContainer {
        let config = ModelConfiguration(
            "TimeKeeper",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
