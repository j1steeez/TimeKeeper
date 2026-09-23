import Foundation
import SwiftData

public enum SeedData {
    public static let photoBasenames: [String] = [
        "submariner.jpg", "speedmaster.jpg", "snowflake.jpg",
        "black-bay.jpg", "reverso.jpg", "santos.jpg"
    ]

    public static func makeSeedWatches(now: Date = .now) -> [Watch] {
        let cal = Calendar.current
        func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: now) ?? now }

        return [
            Watch(id: "seed-rolex-submariner", brand: "Rolex", name: "Submariner Date",
                  reference: "126610LN", status: .next, tier: .highEnd, priority: 5,
                  priceTarget: 10_250, currency: "USD", caseSize: "41mm",
                  movement: "Calibre 3235", material: "Oystersteel",
                  notes: "Ceramic bezel, black dial. Next up.", photoId: "submariner.jpg",
                  createdAt: daysAgo(30), updatedAt: daysAgo(2)),
            Watch(id: "seed-omega-speedmaster", brand: "Omega", name: "Speedmaster Professional",
                  reference: "310.30.42.50.01.001", status: .shortlisted, tier: .highEnd, priority: 4,
                  priceTarget: 7_400, currency: "USD", caseSize: "42mm",
                  movement: "Calibre 3861", material: "Stainless steel",
                  notes: "Moonwatch. Hesalite option preferred.", photoId: "speedmaster.jpg",
                  createdAt: daysAgo(28), updatedAt: daysAgo(5)),
            Watch(id: "seed-gs-snowflake", brand: "Grand Seiko", name: "Snowflake",
                  reference: "SBGA211", status: .shortlisted, tier: .highEnd, priority: 4,
                  priceTarget: 6_800, currency: "USD", caseSize: "41mm",
                  movement: "9R65 Spring Drive", material: "Stainless steel",
                  notes: "Zaratsu polish. Snowflake dial.", photoId: "snowflake.jpg",
                  createdAt: daysAgo(25), updatedAt: daysAgo(7)),
            Watch(id: "seed-tudor-bb58", brand: "Tudor", name: "Black Bay 58",
                  reference: "79030N", status: .considering, tier: .cheap, priority: 3,
                  priceTarget: 3_750, currency: "USD", caseSize: "39mm",
                  movement: "MT5402", material: "Stainless steel",
                  notes: "Black dial, gilt accents.", photoId: "black-bay.jpg",
                  createdAt: daysAgo(20), updatedAt: daysAgo(10)),
            Watch(id: "seed-jlc-reverso", brand: "Jaeger-LeCoultre", name: "Reverso Classic",
                  reference: "Q3848420", status: .sold, tier: .highEnd, priority: 2,
                  priceTarget: 8_900, pricePaid: 7_200, soldPrice: 8_100, currency: "USD",
                  caseSize: "45.6 × 27.4mm", movement: "Calibre 822", material: "Stainless steel",
                  notes: "Sold — kept for history.", photoId: "reverso.jpg",
                  createdAt: daysAgo(90), updatedAt: daysAgo(40)),
            Watch(id: "seed-cartier-santos", brand: "Cartier", name: "Santos de Cartier",
                  reference: "WSSA0029", status: .acquired, tier: .highEnd, priority: 3,
                  priceTarget: 7_700, pricePaid: 7_450, currency: "USD", caseSize: "Medium",
                  movement: "1847 MC", material: "Steel",
                  notes: "Medium size, quick-switch bracelet.", photoId: "santos.jpg",
                  createdAt: daysAgo(60), updatedAt: daysAgo(15))
        ]
    }

    @MainActor
    public static func seedIfEmpty(into context: ModelContext) throws -> Int {
        var descriptor = FetchDescriptor<Watch>()
        descriptor.fetchLimit = 1
        guard try context.fetch(descriptor).isEmpty else { return 0 }
        let seeds = makeSeedWatches()
        for w in seeds { context.insert(w) }
        try context.save()
        return seeds.count
    }
}
