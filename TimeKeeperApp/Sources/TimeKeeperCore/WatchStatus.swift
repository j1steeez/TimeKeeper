import Foundation

/// Watch lifecycle status — raw values match the Electron IndexedDB schema.
public enum WatchStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case considering
    case shortlisted
    case next
    case onHold = "on-hold"
    case acquired
    case sold

    public var id: String { rawValue }

    public var displayLabel: String {
        switch self {
        case .considering: return "Want"
        case .shortlisted: return "Saved"
        case .next:        return "Next"
        case .onHold:      return "Hold"
        case .acquired:    return "Owned"
        case .sold:        return "Sold"
        }
    }

    public var systemImage: String {
        switch self {
        case .considering: return "eye"
        case .shortlisted: return "bookmark"
        case .next:        return "arrow.right.circle"
        case .onHold:      return "pause.circle"
        case .acquired:    return "checkmark.circle"
        case .sold:        return "tag"
        }
    }

    public var isWant: Bool {
        switch self {
        case .acquired, .sold: return false
        default: return true
        }
    }
}

/// Collection tier — Rep / Cheap / High-end.
public enum WatchTier: String, Codable, CaseIterable, Identifiable, Sendable {
    case rep
    case cheap
    case highEnd

    public var id: String { rawValue }

    public var displayLabel: String {
        switch self {
        case .rep:     return "Rep"
        case .cheap:   return "Cheap"
        case .highEnd: return "High-end"
        }
    }
}

/// Tier chip filter (All + three tiers).
public enum WatchTierFilter: String, CaseIterable, Identifiable, Sendable {
    case all, rep, cheap, highEnd

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all:     return "All"
        case .rep:     return WatchTier.rep.displayLabel
        case .cheap:   return WatchTier.cheap.displayLabel
        case .highEnd: return WatchTier.highEnd.displayLabel
        }
    }

    public var tier: WatchTier? {
        switch self {
        case .all: return nil
        case .rep: return .rep
        case .cheap: return .cheap
        case .highEnd: return .highEnd
        }
    }
}

/// Top-level sections (tabs / sidebar).
public enum WatchSection: String, CaseIterable, Identifiable, Sendable {
    case wants, owned, sold, removed

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .wants:   return "Wants"
        case .owned:   return "Owned"
        case .sold:    return "Sold"
        case .removed: return "Removed"
        }
    }

    public var systemImage: String {
        switch self {
        case .wants:   return "heart"
        case .owned:   return "checkmark.seal.fill"
        case .sold:    return "tag"
        case .removed: return "archivebox"
        }
    }

    public var emptyTitle: String {
        switch self {
        case .wants:   return "Nothing on the list yet"
        case .owned:   return "No pieces owned"
        case .sold:    return "No sales recorded"
        case .removed: return "Removed bin is empty"
        }
    }

    public var emptyMessage: String {
        switch self {
        case .wants:   return "Track watches you’re considering, shortlisting, or buying next."
        case .owned:   return "Mark a watch as Owned when it joins your collection."
        case .sold:    return "Sold pieces live here for history and price memory."
        case .removed: return "Pieces you soft-remove land here. Add them back anytime — permanent delete only lives in this bin."
        }
    }

    public var emptyCTA: String {
        switch self {
        case .wants:   return "Add a watch"
        case .owned:   return "Add an owned watch"
        case .sold:    return "Log a sold watch"
        case .removed: return ""
        }
    }

    public var showsAddCTA: Bool { self != .removed }

    public func matches(_ watch: Watch) -> Bool {
        switch self {
        case .removed: return watch.isRemoved
        case .wants:   return !watch.isRemoved && watch.status.isWant
        case .owned:   return !watch.isRemoved && watch.status == .acquired
        case .sold:    return !watch.isRemoved && watch.status == .sold
        }
    }

    public var defaultStatusForNewWatch: WatchStatus {
        switch self {
        case .wants, .removed: return .considering
        case .owned: return .acquired
        case .sold:  return .sold
        }
    }
}

public enum WatchSort: String, CaseIterable, Identifiable, Sendable {
    case priority, newest, priceAsc, priceDesc

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .priority:  return "Priority"
        case .newest:    return "Newest"
        case .priceAsc:  return "Price ↑"
        case .priceDesc: return "Price ↓"
        }
    }

    public var systemImage: String {
        switch self {
        case .priority:  return "star"
        case .newest:    return "clock"
        case .priceAsc:  return "arrow.up"
        case .priceDesc: return "arrow.down"
        }
    }
}
