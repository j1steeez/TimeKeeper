import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Dark-forward editorial tokens — Chrono24 / Hodinkee energy, not neon hype.
enum TKTheme {
    static let cardCorner: CGFloat = 14
    static let photoAspect: CGFloat = 1.0
    static let gridSpacing: CGFloat = 22
    static let contentPadding: CGFloat = 18
    static let brandTracking: CGFloat = 2.4

    /// Near-black editorial (dark) / warm paper (light) — never pure void or stark white.
    static var canvas: Color { adaptive(light: (0.955, 0.945, 0.925), dark: (0.07, 0.07, 0.075)) }
    /// Warm ivory surface in light; raised charcoal in dark.
    static var surface: Color { adaptive(light: (0.99, 0.985, 0.97), dark: (0.11, 0.11, 0.12)) }
    static var ink: Color { adaptive(light: (0.13, 0.12, 0.10), dark: (0.94, 0.92, 0.88)) }
    static var inkSecondary: Color { adaptive(light: (0.42, 0.40, 0.36), dark: (0.64, 0.62, 0.57)) }
    /// Champagne brass — CTAs, priority, selected chips only.
    static var brass: Color { adaptive(light: (0.58, 0.48, 0.30), dark: (0.80, 0.70, 0.50)) }
    static var hairline: Color { adaptive(light: (0.78, 0.75, 0.70), dark: (0.28, 0.28, 0.30)).opacity(0.85) }
    static var subtleFill: Color { adaptive(light: (0.93, 0.91, 0.87), dark: (0.16, 0.16, 0.17)) }
    /// Soft bin accent — not alarmist system orange.
    static var removedAccent: Color { adaptive(light: (0.55, 0.42, 0.32), dark: (0.72, 0.58, 0.44)) }

    static func tierColor(_ tier: WatchTier) -> Color {
        switch tier {
        // Copper-amber — warm, distinct from high-end champagne
        case .rep:     return adaptive(light: (0.68, 0.48, 0.22), dark: (0.86, 0.66, 0.36))
        // Cool slate — readable “Cheap”, not muddy system gray
        case .cheap:   return adaptive(light: (0.38, 0.46, 0.54), dark: (0.68, 0.74, 0.80))
        // Rich champagne gold
        case .highEnd: return adaptive(light: (0.52, 0.42, 0.26), dark: (0.90, 0.78, 0.54))
        }
    }

    static func displayTitleFont() -> Font { .system(.largeTitle, design: .serif).weight(.medium) }
    static func cardNameFont() -> Font { .system(.headline, design: .serif).weight(.medium) }
    static func sectionHeaderFont() -> Font { .system(.subheadline, design: .serif).weight(.semibold) }
    static func metaLabelFont() -> Font { .caption.weight(.medium) }

    private static func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        #if os(iOS)
        Color(uiColor: UIColor { t in
            let c = t.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
        #elseif os(macOS)
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let c = isDark ? dark : light
            return NSColor(calibratedRed: c.0, green: c.1, blue: c.2, alpha: 1)
        })
        #else
        Color(red: dark.0, green: dark.1, blue: dark.2)
        #endif
    }
}

extension View {
    func tkCardStyle() -> some View {
        background {
            RoundedRectangle(cornerRadius: TKTheme.cardCorner, style: .continuous)
                .fill(TKTheme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: TKTheme.cardCorner, style: .continuous)
                        .strokeBorder(TKTheme.hairline, lineWidth: 0.5)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: TKTheme.cardCorner, style: .continuous))
    }

    func tkCanvasBackground() -> some View {
        background(TKTheme.canvas.ignoresSafeArea())
    }

    func tkPanelStyle(corner: CGFloat = 12) -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(TKTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(TKTheme.hairline, lineWidth: 0.5)
                    }
            }
    }
}

struct PriorityDots: View {
    let priority: Int
    var maxDots: Int = 5
    private var clamped: Int { max(1, min(maxDots, priority)) }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...maxDots, id: \.self) { i in
                Circle()
                    .fill(i <= clamped ? TKTheme.brass : TKTheme.hairline)
                    .frame(width: 5, height: 5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WatchFormatting.priorityAccessibilityLabel(clamped))
    }
}

struct TierBadge: View {
    let tier: WatchTier
    var compact: Bool = false

    var body: some View {
        Text(tier.displayLabel.uppercased())
            .font(.system(compact ? .caption2 : .caption).weight(.semibold))
            .tracking(compact ? 0.8 : 1.2)
            .foregroundStyle(TKTheme.tierColor(tier))
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 3 : 4)
            .background {
                Capsule(style: .continuous)
                    .fill(TKTheme.tierColor(tier).opacity(0.14))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(TKTheme.tierColor(tier).opacity(0.40), lineWidth: 0.5)
                    }
            }
            .accessibilityLabel("Tier \(tier.displayLabel)")
    }
}

struct RemovedBadge: View {
    var compact: Bool = false

    var body: some View {
        Text("REMOVED")
            .font(.system(compact ? .caption2 : .caption).weight(.semibold))
            .tracking(compact ? 0.8 : 1.0)
            .foregroundStyle(TKTheme.removedAccent)
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 3 : 4)
            .background {
                Capsule(style: .continuous)
                    .fill(TKTheme.removedAccent.opacity(0.14))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(TKTheme.removedAccent.opacity(0.35), lineWidth: 0.5)
                    }
            }
            .accessibilityLabel("Removed")
    }
}

struct TierFilterChips: View {
    @Binding var filter: WatchTierFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WatchTierFilter.allCases) { option in
                    Button { filter = option } label: {
                        Text(option.title)
                            .font(.subheadline.weight(filter == option ? .semibold : .regular))
                            .foregroundStyle(chipForeground(option))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background {
                                Capsule(style: .continuous)
                                    .fill(chipFill(option))
                                    .overlay {
                                        Capsule(style: .continuous)
                                            .strokeBorder(chipStroke(option), lineWidth: 0.5)
                                    }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Filter \(option.title)")
                    .accessibilityAddTraits(filter == option ? .isSelected : [])
                }
            }
        }
    }

    private func chipForeground(_ option: WatchTierFilter) -> Color {
        guard filter == option else { return TKTheme.inkSecondary }
        if let tier = option.tier { return TKTheme.tierColor(tier) }
        return TKTheme.ink
    }

    private func chipFill(_ option: WatchTierFilter) -> Color {
        guard filter == option else { return TKTheme.subtleFill }
        if let tier = option.tier { return TKTheme.tierColor(tier).opacity(0.16) }
        return TKTheme.brass.opacity(0.20)
    }

    private func chipStroke(_ option: WatchTierFilter) -> Color {
        guard filter == option else { return TKTheme.hairline }
        if let tier = option.tier { return TKTheme.tierColor(tier).opacity(0.50) }
        return TKTheme.brass.opacity(0.55)
    }
}

/// Form tier picker — badge language/colors, not stock segmented chrome.
struct TierPickerChips: View {
    @Binding var tier: WatchTier

    var body: some View {
        HStack(spacing: 8) {
            ForEach(WatchTier.allCases) { option in
                Button { tier = option } label: {
                    Text(option.displayLabel)
                        .font(.subheadline.weight(tier == option ? .semibold : .regular))
                        .foregroundStyle(tier == option ? TKTheme.tierColor(option) : TKTheme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(tier == option ? TKTheme.tierColor(option).opacity(0.16) : TKTheme.subtleFill)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(
                                            tier == option ? TKTheme.tierColor(option).opacity(0.50) : TKTheme.hairline,
                                            lineWidth: 0.5
                                        )
                                }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tier \(option.displayLabel)")
                .accessibilityAddTraits(tier == option ? .isSelected : [])
            }
        }
    }
}
