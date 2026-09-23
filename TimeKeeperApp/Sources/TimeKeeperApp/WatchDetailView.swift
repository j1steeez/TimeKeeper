import SwiftUI
import SwiftData

struct WatchDetailView: View {
    @Bindable var watch: Watch
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false
    @State private var confirmSoftRemove = false
    @State private var confirmHardDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                WatchPhotoView(photoId: watch.photoId)
                    .aspectRatio(1.15, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: TKTheme.cardCorner, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: TKTheme.cardCorner, style: .continuous)
                            .strokeBorder(TKTheme.hairline, lineWidth: 0.5)
                    }
                    .accessibilityLabel("Photo of \(watch.displayTitle)")

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(watch.brand.uppercased())
                            .font(.subheadline.weight(.semibold))
                            .tracking(TKTheme.brandTracking)
                            .foregroundStyle(TKTheme.inkSecondary)
                        Spacer(minLength: 8)
                        TierBadge(tier: watch.tier)
                    }

                    Text(watch.name)
                        .font(TKTheme.displayTitleFont())
                        .foregroundStyle(TKTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if !watch.reference.isEmpty {
                        Text(watch.reference)
                            .font(.title3.monospaced())
                            .foregroundStyle(TKTheme.inkSecondary)
                    }

                    HStack(spacing: 12) {
                        Label(watch.status.displayLabel, systemImage: watch.status.systemImage)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(TKTheme.ink)
                        PriorityDots(priority: watch.priority)
                        if watch.isRemoved {
                            RemovedBadge()
                        }
                    }
                    .padding(.top, 4)

                    if watch.isRemoved {
                        VStack(spacing: 8) {
                            Button {
                                watch.restore()
                                try? modelContext.save()
                            } label: {
                                Label("Add back to collection", systemImage: "arrow.uturn.backward")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(TKTheme.ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(TKTheme.brass.opacity(0.28))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(TKTheme.brass.opacity(0.55), lineWidth: 0.5)
                                            }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Restores this watch to its previous section")

                            Button {
                                confirmHardDelete = true
                            } label: {
                                Label("Delete forever", systemImage: "trash")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(TKTheme.removedAccent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(TKTheme.removedAccent.opacity(0.12))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(TKTheme.removedAccent.opacity(0.40), lineWidth: 0.5)
                                            }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Permanently deletes this watch")
                        }
                        .padding(.top, 8)
                    }
                }

                moneySection
                specsSection
                notesSection
            }
            .padding(TKTheme.contentPadding)
        }
        .tkCanvasBackground()
        .navigationTitle(watch.name.isEmpty ? watch.brand : watch.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit", systemImage: "pencil") { showEdit = true }
                    if watch.isRemoved {
                        Button("Add back", systemImage: "arrow.uturn.backward") {
                            watch.restore()
                            try? modelContext.save()
                        }
                        Button("Delete forever", systemImage: "trash", role: .destructive) {
                            confirmHardDelete = true
                        }
                    } else {
                        Button("Move to Removed", systemImage: "archivebox", role: .destructive) {
                            confirmSoftRemove = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(TKTheme.brass)
                }
                .accessibilityLabel("Watch actions")
            }
        }
        .tint(TKTheme.brass)
        .sheet(isPresented: $showEdit) {
            WatchFormView(existing: watch)
        }
        .confirmationDialog("Move to Removed?", isPresented: $confirmSoftRemove, titleVisibility: .visible) {
            Button("Move to Removed", role: .destructive) {
                watch.softRemove()
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It lands in the Removed bin. You can add it back later — permanent delete only lives there.")
        }
        .confirmationDialog("Delete forever?", isPresented: $confirmHardDelete, titleVisibility: .visible) {
            Button("Delete forever", role: .destructive) {
                PhotoStore.deleteUserPhoto(photoId: watch.photoId)
                modelContext.delete(watch)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes the watch and cannot be undone.")
        }
    }

    @ViewBuilder
    private var moneySection: some View {
        let rows: [(String, String)] = [
            ("Target", WatchFormatting.price(watch.priceTarget, currency: watch.currency)),
            ("Paid", WatchFormatting.price(watch.pricePaid, currency: watch.currency)),
            ("Sold", WatchFormatting.price(watch.soldPrice, currency: watch.currency))
        ].filter { $0.1 != "—" }

        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Money")
                    .font(TKTheme.sectionHeaderFont())
                    .foregroundStyle(TKTheme.ink)
                ForEach(rows, id: \.0) { label, value in
                    HStack {
                        Text(label)
                            .font(TKTheme.metaLabelFont())
                            .foregroundStyle(TKTheme.inkSecondary)
                            .frame(width: 100, alignment: .leading)
                        Text(value)
                            .foregroundStyle(TKTheme.ink)
                            .fontWeight(.medium)
                        Spacer(minLength: 0)
                    }
                    .font(.body)
                }
            }
            .tkPanelStyle()
        }
    }

    @ViewBuilder
    private var specsSection: some View {
        let rows: [(String, String)] = [
            ("Case", watch.caseSize),
            ("Movement", watch.movement),
            ("Material", watch.material),
            ("Retailer", watch.retailer),
            ("URL", watch.url)
        ].filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Details")
                    .font(TKTheme.sectionHeaderFont())
                    .foregroundStyle(TKTheme.ink)
                ForEach(rows, id: \.0) { label, value in
                    HStack(alignment: .top) {
                        Text(label)
                            .font(TKTheme.metaLabelFont())
                            .foregroundStyle(TKTheme.inkSecondary)
                            .frame(width: 100, alignment: .leading)
                        if label == "URL", let link = URL(string: value) {
                            Link(value, destination: link)
                                .foregroundStyle(TKTheme.brass)
                                .lineLimit(2)
                        } else {
                            Text(value)
                                .foregroundStyle(TKTheme.ink)
                                .textSelection(.enabled)
                        }
                        Spacer(minLength: 0)
                    }
                    .font(.body)
                }
            }
            .tkPanelStyle()
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        if !watch.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(TKTheme.sectionHeaderFont())
                    .foregroundStyle(TKTheme.ink)
                Text(watch.notes)
                    .font(.body)
                    .foregroundStyle(TKTheme.ink)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
