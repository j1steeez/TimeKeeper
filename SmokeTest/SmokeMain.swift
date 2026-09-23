import Foundation
import SwiftData

@main
struct TimeKeeperSmokeMain {
    static func main() {
        do {
            try MainActor.assumeIsolated {
                try run()
            }
            print("SMOKE_PASS")
        } catch {
            fputs("SMOKE_FAIL: \(error)\n", stderr)
            exit(1)
        }
    }

    @MainActor
    static func run() throws {
        let schema = Schema([Watch.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)

        let seeded = try SeedData.seedIfEmpty(into: context)
        precondition(seeded == 6, "expected 6 seeds, got \(seeded)")
        var all = try context.fetch(FetchDescriptor<Watch>())
        precondition(all.count == 6)

        let w = Watch(brand: "Smoke", name: "Test", status: .considering, priority: 4, priceTarget: 1000)
        context.insert(w)
        try context.save()
        all = try context.fetch(FetchDescriptor<Watch>())
        precondition(all.contains { $0.id == w.id })

        w.name = "Test Edited"
        w.pricePaid = 900
        w.applyStatus(.acquired)
        try context.save()
        precondition(w.status == .acquired && w.pricePaid == 900)

        w.soldPrice = 1100
        w.applyStatus(.sold)
        try context.save()
        precondition(w.status == .sold && w.displayPrice == 1100)

        let wants = WatchQuery.filtered(all, section: .wants, search: "Rolex")
        precondition(!wants.isEmpty)

        let sold = WatchQuery.filtered(try context.fetch(FetchDescriptor<Watch>()), section: .sold, search: "")
        precondition(sold.contains { $0.id == w.id })

        let snapshot = try context.fetch(FetchDescriptor<Watch>())
        let data = try ExportImport.exportJSON(watches: snapshot)
        let envelope = try ExportImport.decodeEnvelope(from: data)
        precondition(envelope.watches.count == snapshot.count)

        let container2 = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let context2 = ModelContext(container2)
        let imported = try ExportImport.importEnvelope(envelope, into: context2)
        precondition(imported == snapshot.count)
        let again = try context2.fetch(FetchDescriptor<Watch>())
        precondition(again.contains { $0.brand == "Smoke" && $0.soldPrice == 1100 })

        context.delete(w)
        try context.save()
        let after = try context.fetch(FetchDescriptor<Watch>())
        precondition(!after.contains { $0.id == w.id })

        print("checks: seed/add/edit/status/prices/search/export-import/delete OK")
    }
}
