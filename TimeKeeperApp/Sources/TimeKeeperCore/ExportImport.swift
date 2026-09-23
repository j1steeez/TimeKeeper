import Foundation
import SwiftData

public enum ExportImport {
    public struct Envelope: Codable, Sendable {
        public var version: Int
        public var exportedAt: String
        public var watches: [WatchDTO]

        public init(version: Int = 2, exportedAt: Date = .now, watches: [WatchDTO]) {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.version = version
            self.exportedAt = iso.string(from: exportedAt)
            self.watches = watches
        }
    }

    public static func exportJSON(watches: [Watch]) throws -> Data {
        let envelope = Envelope(watches: watches.map(WatchDTO.init(from:)))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(envelope)
    }

    public static func decodeEnvelope(from data: Data) throws -> Envelope {
        try JSONDecoder().decode(Envelope.self, from: data)
    }

    @MainActor
    public static func importEnvelope(_ envelope: Envelope, into context: ModelContext) throws -> Int {
        let existing = try context.fetch(FetchDescriptor<Watch>())
        var byId = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        var count = 0
        for dto in envelope.watches {
            if let current = byId[dto.id] {
                current.brand = dto.brand
                current.name = dto.name
                current.reference = dto.reference
                current.statusRaw = dto.status
                current.tierRaw = dto.tier ?? WatchTier.highEnd.rawValue
                current.priority = dto.priority
                current.priceTarget = dto.priceTarget
                current.pricePaid = dto.pricePaid
                current.soldPrice = dto.soldPrice
                current.currency = dto.currency
                current.caseSize = dto.caseSize
                current.movement = dto.movement
                current.material = dto.material
                current.retailer = dto.retailer
                current.url = dto.url
                current.notes = dto.notes
                current.photoId = dto.photoId
                current.isRemoved = dto.isRemoved ?? false
                current.removedAt = dto.removedAt.flatMap(WatchDTO.parseDate)
                current.createdAt = WatchDTO.parseDate(dto.createdAt) ?? current.createdAt
                current.updatedAt = WatchDTO.parseDate(dto.updatedAt) ?? .now
            } else {
                let watch = dto.makeWatch()
                context.insert(watch)
                byId[watch.id] = watch
            }
            count += 1
        }
        try context.save()
        return count
    }
}
