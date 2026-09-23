import SwiftUI

struct EmptyStateView: View {
    let section: WatchSection
    let action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 40)
            Image(systemName: section.systemImage)
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(TKTheme.brass)
                .symbolRenderingMode(.monochrome)
                .accessibilityHidden(true)

            Text(section.emptyTitle)
                .font(.system(.title2, design: .serif).weight(.medium))
                .foregroundStyle(TKTheme.ink)
                .multilineTextAlignment(.center)

            Text(section.emptyMessage)
                .font(.body)
                .foregroundStyle(TKTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            if section.showsAddCTA {
                Button(action: action) {
                    Label(section.emptyCTA, systemImage: "plus")
                        .font(.body.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundStyle(TKTheme.ink)
                        .background {
                            Capsule(style: .continuous)
                                .fill(TKTheme.brass.opacity(0.28))
                                .overlay {
                                    Capsule(style: .continuous)
                                        .strokeBorder(TKTheme.brass.opacity(0.55), lineWidth: 0.5)
                                }
                        }
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                .accessibilityHint("Opens the form to add a new watch")
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(TKTheme.contentPadding)
    }
}
