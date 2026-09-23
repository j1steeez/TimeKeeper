import SwiftUI

struct OnboardingView: View {
    var onDone: () -> Void

    private let pages: [(title: String, body: String, symbol: String)] = [
        ("Want. Own. Sell.", "A private catalog for pieces you chase, wear, and let go — Rep, Cheap, or High-end.", "wristwatch"),
        ("Stay organized", "Filter by tier, sort by priority or price, and soft-remove anything you’d rather park than delete.", "slider.horizontal.3"),
        ("Your data stays local", "Watches live on this device. Export a JSON backup anytime from the menu.", "internaldrive")
    ]

    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Spacer(minLength: 24)
                ZStack {
                    Circle()
                        .fill(TKTheme.brass.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: pages[page].symbol)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(TKTheme.brass)
                        .symbolRenderingMode(.monochrome)
                }
                .accessibilityHidden(true)
                Text(pages[page].title)
                    .font(.system(.largeTitle, design: .serif).weight(.semibold))
                    .foregroundStyle(TKTheme.ink)
                    .multilineTextAlignment(.center)
                Text(pages[page].body)
                    .font(.body)
                    .foregroundStyle(TKTheme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle()
                            .fill(i == page ? TKTheme.brass : TKTheme.hairline)
                            .frame(width: 7, height: 7)
                    }
                }
                .accessibilityHidden(true)
                Spacer()
            }

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    onDone()
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(TKTheme.brass)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .tkCanvasBackground()
        #if os(macOS)
        .frame(width: 480, height: 420)
        #endif
    }
}
