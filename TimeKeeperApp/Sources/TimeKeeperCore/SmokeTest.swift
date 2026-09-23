import Foundation
import SwiftData

/// In-process smoke: CRUD, tier, soft-remove/restore, JSON round-trip.
public enum SmokeTest {
    public static let passToken = "SMOKE_PASS"

    @MainActor
    public static func run(inMemory: Bool = true) throws -> String {
        let container = try Persistence.makeContainer(inMemory: inMemory)
        let context = container.mainContext

        let watch = Watch(
            brand: "Smoke",
            name: "Chronograph",
            reference: "SMK-001",
            status: .considering,
            tier: .rep,
            priority: 4,
            priceTarget: 1_200,
            currency: "USD",
            notes: "smoke tier rep"
        )
        // Property-declaration defaults (migration-safe) when isRemoved/tier omitted
        let defaultsWatch = Watch(brand: "Default", name: "Check")
        guard defaultsWatch.isRemoved == false, defaultsWatch.tier == .highEnd else {
            throw SmokeError.fail("Watch property defaults wrong (isRemoved/tier)")
        }

        context.insert(watch)
        try context.save()
        guard watch.tier == .rep else { throw SmokeError.fail("tier not persisted") }

        watch.softRemove()
        try context.save()
        let all = try context.fetch(FetchDescriptor<Watch>())
        let wants = WatchQuery.filtered(all, section: .wants, search: "")
        let removed = WatchQuery.filtered(all, section: .removed, search: "")
        guard wants.isEmpty, removed.contains(where: { $0.id == watch.id }) else {
            throw SmokeError.fail("soft remove not reflected")
        }

        watch.restore()
        try context.save()
        let wants2 = WatchQuery.filtered(try context.fetch(FetchDescriptor<Watch>()), section: .wants, search: "")
        guard wants2.contains(where: { $0.id == watch.id }), !watch.isRemoved else {
            throw SmokeError.fail("restore failed")
        }

        watch.tier = .cheap
        try context.save()
        let cheapOnly = WatchQuery.filtered(
            try context.fetch(FetchDescriptor<Watch>()),
            section: .wants, search: "", tierFilter: .cheap
        )
        guard cheapOnly.contains(where: { $0.id == watch.id }) else {
            throw SmokeError.fail("tier filter failed")
        }
        let byWord = WatchQuery.filtered(
            try context.fetch(FetchDescriptor<Watch>()),
            section: .wants, search: "cheap"
        )
        guard byWord.contains(where: { $0.id == watch.id }) else {
            throw SmokeError.fail("tier not in search haystack")
        }

        watch.status = .acquired
        watch.pricePaid = 1_050
        watch.touch()
        try context.save()
        watch.status = .sold
        watch.soldPrice = 1_400
        watch.touch()
        try context.save()

        let data = try ExportImport.exportJSON(watches: try context.fetch(FetchDescriptor<Watch>()))
        let envelope = try ExportImport.decodeEnvelope(from: data)
        guard let dto = envelope.watches.first(where: { $0.id == watch.id }) else {
            throw SmokeError.fail("export missing watch")
        }
        guard dto.tier == WatchTier.cheap.rawValue,
              dto.pricePaid == 1_050,
              dto.soldPrice == 1_400,
              dto.isRemoved == false else {
            throw SmokeError.fail("DTO missing new fields")
        }

        watch.softRemove()
        try context.save()
        context.delete(watch)
        try context.save()
        guard try context.fetch(FetchDescriptor<Watch>()).isEmpty else {
            throw SmokeError.fail("hard delete failed")
        }

        let legacy = """
        {"version":1,"exportedAt":"2026-09-22T12:00:00.000Z","watches":[{
          "id":"legacy-1","brand":"Legacy","name":"Piece","reference":"",
          "status":"considering","priority":3,"currency":"USD",
          "caseSize":"","movement":"","material":"","retailer":"","url":"","notes":"",
          "createdAt":"2026-09-22T12:00:00.000Z","updatedAt":"2026-09-22T12:00:00.000Z"
        }]}
        """.data(using: .utf8)!
        let legacyEnv = try ExportImport.decodeEnvelope(from: legacy)
        _ = try ExportImport.importEnvelope(legacyEnv, into: context)
        let legacyWatch = try context.fetch(FetchDescriptor<Watch>()).first { $0.id == "legacy-1" }
        guard let legacyWatch, legacyWatch.tier == .highEnd, legacyWatch.isRemoved == false else {
            throw SmokeError.fail("legacy import defaults wrong")
        }

        return passToken
    }

    public enum SmokeError: Error, CustomStringConvertible {
        case fail(String)
        public var description: String {
            switch self {
            case .fail(let msg): return "SMOKE_FAIL: \(msg)"
            }
        }
    }
}
