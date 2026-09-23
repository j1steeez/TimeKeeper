import SwiftUI

struct WatchCardView: View {
    let watch: Watch
    var showsRemovedTreatment: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                // Constrain aspect first so fill cannot overflow into neighboring grid cells.
                Color.clear
                    .aspectRatio(TKTheme.photoAspect, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        WatchPhotoView(photoId: watch.photoId)
                            .opacity(showsRemovedTreatment ? 0.72 : 1)
                    }
                    .clipped()
                    .accessibilityHidden(true)

                VStack(alignment: .trailing, spacing: 4) {
                    TierBadge(tier: watch.tier, compact: true)
                    if showsRemovedTreatment {
                        RemovedBadge(compact: true)
                    }
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(watch.brand.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(TKTheme.brandTracking)
                    .foregroundStyle(TKTheme.inkSecondary)
                    .lineLimit(1)

                Text(watch.name)
                    .font(TKTheme.cardNameFont())
                    .lineLimit(2)
                    .foregroundStyle(TKTheme.ink)

                if !watch.reference.isEmpty {
                    Text(watch.reference)
                        .font(.caption.monospaced())
                        .foregroundStyle(TKTheme.inkSecondary.opacity(0.85))
                        .lineLimit(1)
                }

                HStack(alignment: .center, spacing: 8) {
                    Text(WatchFormatting.statusPriceLine(
                        status: watch.status,
                        priceTarget: watch.priceTarget,
                        currency: watch.currency
                    ))
                    .font(.subheadline)
                    .foregroundStyle(TKTheme.inkSecondary)
                    .lineLimit(1)

                    Spacer(minLength: 4)
                    PriorityDots(priority: watch.priority)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tkCardStyle()
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(summary)
        .accessibilityAddTraits(.isButton)
    }

    private var summary: String {
        let price = WatchFormatting.price(watch.priceTarget, currency: watch.currency)
        var parts = [
            watch.displayTitle,
            watch.tier.displayLabel,
            watch.status.displayLabel,
            price,
            WatchFormatting.priorityAccessibilityLabel(watch.priority)
        ]
        if showsRemovedTreatment { parts.append("Removed") }
        return parts.joined(separator: ", ")
    }
}
