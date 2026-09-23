import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Watch.updatedAt, order: .reverse) private var allWatches: [Watch]

    @AppStorage("timekeeper.onboardingDone") private var onboardingDone = false

    @State private var section: WatchSection = .wants
    @State private var searchText = ""
    @State private var sort: WatchSort = .priority
    @State private var tierFilter: WatchTierFilter = .all
    @State private var selectedWatchID: String?
    @State private var showAdd = false
    @State private var didSeed = false

    var body: some View {
        Group {
            #if os(macOS)
            macRoot
            #else
            iosRoot
            #endif
        }
        .sheet(isPresented: $showAdd) {
            WatchFormView(defaultStatus: section.defaultStatusForNewWatch)
        }
        .modifier(OnboardingPresenter(
            isPresented: Binding(
                get: { !onboardingDone },
                set: { if !$0 { onboardingDone = true } }
            ),
            onDone: { onboardingDone = true }
        ))
        .task {
            guard !didSeed else { return }
            didSeed = true
            _ = try? SeedData.seedIfEmpty(into: modelContext)
        }
        .onChange(of: section) { _, _ in selectedWatchID = nil }
    }

    #if os(macOS)
    private var macRoot: some View {
        NavigationSplitView {
            List(selection: $section) {
                ForEach(WatchSection.allCases) { s in
                    Label(s.title, systemImage: s.systemImage).tag(s)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 240)
            .safeAreaInset(edge: .bottom) {
                Button { showAdd = true } label: {
                    Label("Add Watch", systemImage: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(TKTheme.brass)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)
                .padding(12)
                .accessibilityLabel("Add watch")
            }
            .tint(TKTheme.brass)
        } detail: {
            NavigationStack {
                SectionBrowser(
                    section: $section,
                    searchText: $searchText,
                    sort: $sort,
                    tierFilter: $tierFilter,
                    watches: allWatches,
                    showSegmentedControl: true,
                    onSelect: { selectedWatchID = $0.id },
                    onAdd: { showAdd = true },
                    onSoftRemove: softRemove,
                    onRestore: restore,
                    onHardDelete: hardDelete
                )
                .toolbar {
                    ToolbarItem(placement: .automatic) { BackupToolbarMenu() }
                }
                .navigationDestination(item: $selectedWatchID) { id in
                    if let watch = allWatches.first(where: { $0.id == id }) {
                        WatchDetailView(watch: watch)
                    } else {
                        ContentUnavailableView("Watch not found", systemImage: "wristwatch")
                    }
                }
            }
        }
        .navigationTitle("TimeKeeper")
    }
    #endif

    #if os(iOS)
    private var iosRoot: some View {
        TabView(selection: $section) {
            ForEach(WatchSection.allCases) { s in
                NavigationStack {
                    SectionBrowser(
                        section: .constant(s),
                        searchText: $searchText,
                        sort: $sort,
                        tierFilter: $tierFilter,
                        watches: allWatches,
                        showSegmentedControl: false,
                        onSelect: { selectedWatchID = $0.id },
                        onAdd: { showAdd = true },
                        onSoftRemove: softRemove,
                        onRestore: restore,
                        onHardDelete: hardDelete
                    )
                    .navigationTitle("TimeKeeper")
                    .navigationBarTitleDisplayMode(.large)
                    .navigationDestination(item: $selectedWatchID) { id in
                        if let watch = allWatches.first(where: { $0.id == id }) {
                            WatchDetailView(watch: watch)
                        } else {
                            ContentUnavailableView("Watch not found", systemImage: "wristwatch")
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) { BackupToolbarMenu() }
                        if s != .removed {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button { showAdd = true } label: {
                                    Image(systemName: "plus")
                                }
                                .accessibilityLabel("Add watch")
                            }
                        }
                    }
                }
                .tabItem { Label(s.title, systemImage: s.systemImage) }
                .tag(s)
            }
        }
        .tint(TKTheme.brass)
    }
    #endif

    private func softRemove(_ watch: Watch) {
        watch.softRemove()
        try? modelContext.save()
        if selectedWatchID == watch.id { selectedWatchID = nil }
    }

    private func restore(_ watch: Watch) {
        watch.restore()
        try? modelContext.save()
    }

    private func hardDelete(_ watch: Watch) {
        PhotoStore.deleteUserPhoto(photoId: watch.photoId)
        modelContext.delete(watch)
        try? modelContext.save()
        if selectedWatchID == watch.id { selectedWatchID = nil }
    }
}

struct SectionBrowser: View {
    @Binding var section: WatchSection
    @Binding var searchText: String
    @Binding var sort: WatchSort
    @Binding var tierFilter: WatchTierFilter
    let watches: [Watch]
    var showSegmentedControl: Bool
    var onSelect: (Watch) -> Void
    var onAdd: () -> Void
    var onSoftRemove: (Watch) -> Void
    var onRestore: (Watch) -> Void
    var onHardDelete: (Watch) -> Void

    private var visible: [Watch] {
        WatchQuery.sorted(
            WatchQuery.filtered(watches, section: section, search: searchText, tierFilter: tierFilter),
            by: sort
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            WatchBrowserToolbar(searchText: $searchText, sort: $sort)
                .padding(.horizontal, TKTheme.contentPadding)
                .padding(.top, 8)
                .padding(.bottom, 4)

            if showSegmentedControl {
                Picker("Section", selection: $section) {
                    ForEach(WatchSection.allCases) { s in Text(s.title).tag(s) }
                }
                .pickerStyle(.segmented)
                .tint(TKTheme.brass)
                .padding(.horizontal, TKTheme.contentPadding)
                .padding(.bottom, 8)
                .labelsHidden()
                .accessibilityLabel("Collection section")
            }

            if section != .removed {
                TierFilterChips(filter: $tierFilter)
                    .padding(.horizontal, TKTheme.contentPadding)
                    .padding(.bottom, 8)
            }

            if visible.isEmpty {
                EmptyStateView(section: section, action: onAdd)
            } else {
                WatchGridView(
                    watches: visible,
                    showsRemovedActions: section == .removed,
                    onSelect: onSelect,
                    onSoftRemove: onSoftRemove,
                    onRestore: onRestore,
                    onHardDelete: onHardDelete
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tkCanvasBackground()
    }
}

private struct OnboardingPresenter: ViewModifier {
    @Binding var isPresented: Bool
    var onDone: () -> Void

    func body(content: Content) -> some View {
        #if os(iOS)
        content.fullScreenCover(isPresented: $isPresented) { OnboardingView(onDone: onDone) }
        #else
        content.sheet(isPresented: $isPresented) { OnboardingView(onDone: onDone) }
        #endif
    }
}
