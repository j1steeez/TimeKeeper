import SwiftUI

struct WatchGridView: View {
    let watches: [Watch]
    var showsRemovedActions: Bool = false
    var onSelect: (Watch) -> Void
    var onSoftRemove: (Watch) -> Void = { _ in }
    var onRestore: (Watch) -> Void = { _ in }
    var onHardDelete: (Watch) -> Void = { _ in }

    @State private var watchPendingHardDelete: Watch?

    private var columns: [GridItem] {
        if showsRemovedActions {
            // Fewer, wider columns so card + actions don't pack/overlap on Mac.
            [GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 24)]
        } else {
            [GridItem(.adaptive(minimum: 200, maximum: 280), spacing: TKTheme.gridSpacing)]
        }
    }

    private var rowSpacing: CGFloat {
        showsRemovedActions ? 24 : TKTheme.gridSpacing
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: rowSpacing) {
                ForEach(watches, id: \.id) { watch in
                    VStack(spacing: showsRemovedActions ? 10 : 8) {
                        Button { onSelect(watch) } label: {
                            WatchCardView(watch: watch, showsRemovedTreatment: showsRemovedActions)
                                .frame(maxWidth: .infinity, alignment: .top)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .top)

                        if showsRemovedActions {
                            removedActions(for: watch)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .contextMenu {
                        if showsRemovedActions {
                            Button("Add back", systemImage: "arrow.uturn.backward") {
                                onRestore(watch)
                            }
                            Button("Delete forever", systemImage: "trash", role: .destructive) {
                                watchPendingHardDelete = watch
                            }
                        } else {
                            Button("Move to Removed", systemImage: "archivebox", role: .destructive) {
                                onSoftRemove(watch)
                            }
                        }
                    }
                }
            }
            .padding(TKTheme.contentPadding)
        }
        .confirmationDialog(
            "Delete forever?",
            isPresented: Binding(
                get: { watchPendingHardDelete != nil },
                set: { if !$0 { watchPendingHardDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: watchPendingHardDelete
        ) { watch in
            Button("Delete forever", role: .destructive) {
                onHardDelete(watch)
                watchPendingHardDelete = nil
            }
            Button("Cancel", role: .cancel) {
                watchPendingHardDelete = nil
            }
        } message: { watch in
            Text("Permanently deletes \(watch.displayTitle). This cannot be undone.")
        }
    }

    @ViewBuilder
    private func removedActions(for watch: Watch) -> some View {
        VStack(spacing: 8) {
            Button {
                onRestore(watch)
            } label: {
                Label("Add back", systemImage: "arrow.uturn.backward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TKTheme.brass)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(TKTheme.brass.opacity(0.14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(TKTheme.brass.opacity(0.40), lineWidth: 0.5)
                            }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(watch.displayTitle) back to collection")

            Button {
                watchPendingHardDelete = watch
            } label: {
                Label("Delete forever", systemImage: "trash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TKTheme.removedAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(TKTheme.removedAccent.opacity(0.10))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(TKTheme.removedAccent.opacity(0.35), lineWidth: 0.5)
                            }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete \(watch.displayTitle) forever")
        }
        .frame(maxWidth: .infinity)
    }
}

struct WatchBrowserToolbar: View {
    @Binding var searchText: String
    @Binding var sort: WatchSort

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(TKTheme.inkSecondary)
                    .accessibilityHidden(true)
                TextField("Search watches", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(TKTheme.ink)
                    #if os(iOS)
                    .autocorrectionDisabled()
                    #endif
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(TKTheme.inkSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(TKTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(TKTheme.hairline, lineWidth: 0.5)
                    }
            }

            // Single-chrome sort control: Buttons in Menu (no nested Picker).
            Menu {
                ForEach(WatchSort.allCases) { option in
                    Button {
                        sort = option
                    } label: {
                        if sort == option {
                            Label(option.title, systemImage: "checkmark")
                        } else {
                            Text(option.title)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(sort.title)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(TKTheme.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(TKTheme.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(TKTheme.hairline, lineWidth: 0.5)
                        }
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .accessibilityLabel("Sort by \(sort.title)")
        }
    }
}
