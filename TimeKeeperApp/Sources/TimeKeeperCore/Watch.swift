import Foundation
import SwiftData

@Model
public final class Watch {
    @Attribute(.unique) public var id: String
    public var brand: String
    public var name: String
    public var reference: String
    public var statusRaw: String
    public var tierRaw: String = WatchTier.highEnd.rawValue
    public var priority: Int
    public var priceTarget: Double?
    public var pricePaid: Double?
    public var soldPrice: Double?
    public var currency: String
    public var caseSize: String
    public var movement: String
    public var material: String
    public var retailer: String
    public var url: String
    public var notes: String
    public var photoId: String?
    public var isRemoved: Bool = false
    public var removedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public var status: WatchStatus {
        get { WatchStatus(rawValue: statusRaw) ?? .considering }
        set { statusRaw = newValue.rawValue }
    }

    public var tier: WatchTier {
        get { WatchTier(rawValue: tierRaw) ?? .highEnd }
        set { tierRaw = newValue.rawValue }
    }

    public var displayTitle: String {
        let b = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if b.isEmpty { return n.isEmpty ? "Untitled" : n }
        if n.isEmpty { return b }
        return "\(b) \(n)"
    }

    public init(
        id: String = UUID().uuidString,
        brand: String = "",
        name: String = "",
        reference: String = "",
        status: WatchStatus = .considering,
        tier: WatchTier = .highEnd,
        priority: Int = 3,
        priceTarget: Double? = nil,
        pricePaid: Double? = nil,
        soldPrice: Double? = nil,
        currency: String = "USD",
        caseSize: String = "",
        movement: String = "",
        material: String = "",
        retailer: String = "",
        url: String = "",
        notes: String = "",
        photoId: String? = nil,
        isRemoved: Bool = false,
        removedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.brand = brand
        self.name = name
        self.reference = reference
        self.statusRaw = status.rawValue
        self.tierRaw = tier.rawValue
        self.priority = max(1, min(5, priority))
        self.priceTarget = priceTarget
        self.pricePaid = pricePaid
        self.soldPrice = soldPrice
        self.currency = currency.isEmpty ? "USD" : currency
        self.caseSize = caseSize
        self.movement = movement
        self.material = material
        self.retailer = retailer
        self.url = url
        self.notes = notes
        self.photoId = photoId
        self.isRemoved = isRemoved
        self.removedAt = removedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public func touch() { updatedAt = .now }

    public func softRemove() {
        isRemoved = true
        removedAt = .now
        touch()
    }

    public func restore() {
        isRemoved = false
        removedAt = nil
        touch()
    }
}

public enum WatchQuery {
    public static func filtered(
        _ watches: [Watch],
        section: WatchSection,
        search: String,
        tierFilter: WatchTierFilter = .all
    ) -> [Watch] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return watches.filter { watch in
            guard section.matches(watch) else { return false }
            if let wanted = tierFilter.tier, watch.tier != wanted { return false }
            guard !q.isEmpty else { return true }
            let hay = [
                watch.brand, watch.name, watch.reference,
                watch.movement, watch.material, watch.retailer, watch.notes,
                watch.tier.displayLabel, watch.tier.rawValue
            ].joined(separator: " ").lowercased()
            return hay.contains(q)
        }
    }

    public static func sorted(_ watches: [Watch], by sort: WatchSort) -> [Watch] {
        switch sort {
        case .priority:
            return watches.sorted {
                if $0.priority != $1.priority { return $0.priority > $1.priority }
                return $0.updatedAt > $1.updatedAt
            }
        case .newest:
            return watches.sorted { $0.updatedAt > $1.updatedAt }
        case .priceAsc:
            return watches.sorted { ($0.priceTarget ?? .infinity) < ($1.priceTarget ?? .infinity) }
        case .priceDesc:
            return watches.sorted { ($0.priceTarget ?? -.infinity) > ($1.priceTarget ?? -.infinity) }
        }
    }
}

public struct WatchDTO: Codable, Sendable, Equatable {
    public var id: String
    public var brand: String
    public var name: String
    public var reference: String
    public var status: String
    public var tier: String?
    public var priority: Int
    public var priceTarget: Double?
    public var pricePaid: Double?
    public var soldPrice: Double?
    public var currency: String
    public var caseSize: String
    public var movement: String
    public var material: String
    public var retailer: String
    public var url: String
    public var notes: String
    public var photoId: String?
    public var isRemoved: Bool?
    public var removedAt: String?
    public var createdAt: String
    public var updatedAt: String

    public init(from watch: Watch) {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        id = watch.id
        brand = watch.brand
        name = watch.name
        reference = watch.reference
        status = watch.statusRaw
        tier = watch.tierRaw
        priority = watch.priority
        priceTarget = watch.priceTarget
        pricePaid = watch.pricePaid
        soldPrice = watch.soldPrice
        currency = watch.currency
        caseSize = watch.caseSize
        movement = watch.movement
        material = watch.material
        retailer = watch.retailer
        url = watch.url
        notes = watch.notes
        photoId = watch.photoId
        isRemoved = watch.isRemoved
        removedAt = watch.removedAt.map { iso.string(from: $0) }
        createdAt = iso.string(from: watch.createdAt)
        updatedAt = iso.string(from: watch.updatedAt)
    }

    public func makeWatch() -> Watch {
        Watch(
            id: id,
            brand: brand,
            name: name,
            reference: reference,
            status: WatchStatus(rawValue: status) ?? .considering,
            tier: WatchTier(rawValue: tier ?? "") ?? .highEnd,
            priority: priority,
            priceTarget: priceTarget,
            pricePaid: pricePaid,
            soldPrice: soldPrice,
            currency: currency,
            caseSize: caseSize,
            movement: movement,
            material: material,
            retailer: retailer,
            url: url,
            notes: notes,
            photoId: photoId,
            isRemoved: isRemoved ?? false,
            removedAt: removedAt.flatMap(Self.parseDate),
            createdAt: Self.parseDate(createdAt) ?? .now,
            updatedAt: Self.parseDate(updatedAt) ?? .now
        )
    }

    public static func parseDate(_ s: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: s)
    }
}
