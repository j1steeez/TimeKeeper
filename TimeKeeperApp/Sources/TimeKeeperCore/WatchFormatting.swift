import Foundation

public enum WatchFormatting {
    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return f
    }()

    public static func price(_ value: Double?, currency: String = "USD") -> String {
        guard let value else { return "—" }
        let f = currencyFormatter
        f.currencyCode = currency.isEmpty ? "USD" : currency
        return f.string(from: NSNumber(value: value)) ?? "\(currency) \(Int(value))"
    }

    public static func statusPriceLine(status: WatchStatus, priceTarget: Double?, currency: String) -> String {
        "\(status.displayLabel) · \(price(priceTarget, currency: currency))"
    }

    public static func priorityAccessibilityLabel(_ priority: Int) -> String {
        let clamped = max(1, min(5, priority))
        return "Priority \(clamped) of 5"
    }
}
