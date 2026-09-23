import SwiftUI
import SwiftData
import PhotosUI

struct WatchFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var existing: Watch?
    var defaultStatus: WatchStatus = .considering

    @State private var brand = ""
    @State private var name = ""
    @State private var reference = ""
    @State private var status: WatchStatus = .considering
    @State private var tier: WatchTier = .highEnd
    @State private var priority = 3
    @State private var priceText = ""
    @State private var pricePaidText = ""
    @State private var soldPriceText = ""
    @State private var currency = "USD"
    @State private var caseSize = ""
    @State private var movement = ""
    @State private var material = ""
    @State private var retailer = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var photoId: String?
    @State private var pickerItem: PhotosPickerItem?
    @State private var photoRefresh = UUID()

    private var isEditing: Bool { existing != nil }
    private var canSave: Bool {
        !brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        WatchPhotoView(photoId: photoId)
                            .frame(width: 88, height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(TKTheme.hairline, lineWidth: 0.5)
                            }
                            .id(photoRefresh)
                        VStack(alignment: .leading, spacing: 8) {
                            PhotosPicker(selection: $pickerItem, matching: .images) {
                                Label("Choose Photo", systemImage: "photo")
                                    .foregroundStyle(TKTheme.brass)
                            }
                            if photoId != nil {
                                Button("Remove Photo", role: .destructive) {
                                    if let id = photoId, !PhotoStore.isSeedPhoto(id) {
                                        PhotoStore.deleteUserPhoto(photoId: id)
                                    }
                                    photoId = nil
                                    photoRefresh = UUID()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(TKTheme.surface)
                } header: {
                    Text("Photo").foregroundStyle(TKTheme.inkSecondary)
                }

                Section {
                    TextField("Brand", text: $brand)
                    TextField("Model name", text: $name)
                    TextField("Reference", text: $reference)
                } header: {
                    Text("Identity").foregroundStyle(TKTheme.inkSecondary)
                }
                .listRowBackground(TKTheme.surface)

                Section {
                    TierPickerChips(tier: $tier)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowBackground(Color.clear)
                } header: {
                    Text("Tier").foregroundStyle(TKTheme.inkSecondary)
                }

                Section {
                    Picker("Status", selection: $status) {
                        ForEach(WatchStatus.allCases) { s in
                            Label(s.displayLabel, systemImage: s.systemImage).tag(s)
                        }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(1...5, id: \.self) { Text("\($0)").tag($0) }
                    }
                    .accessibilityLabel("Priority from 1 to 5")
                } header: {
                    Text("Status").foregroundStyle(TKTheme.inkSecondary)
                }
                .listRowBackground(TKTheme.surface)

                Section {
                    TextField("Target price", text: $priceText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Price paid", text: $pricePaidText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Sold price", text: $soldPriceText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Currency", text: $currency)
                } header: {
                    Text("Money").foregroundStyle(TKTheme.inkSecondary)
                }
                .listRowBackground(TKTheme.surface)

                Section {
                    TextField("Case size", text: $caseSize)
                    TextField("Movement", text: $movement)
                    TextField("Material", text: $material)
                } header: {
                    Text("Specs").foregroundStyle(TKTheme.inkSecondary)
                }
                .listRowBackground(TKTheme.surface)

                Section {
                    TextField("Retailer", text: $retailer)
                    TextField("URL", text: $url)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                } header: {
                    Text("Source").foregroundStyle(TKTheme.inkSecondary)
                }
                .listRowBackground(TKTheme.surface)

                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("Notes").foregroundStyle(TKTheme.inkSecondary)
                }
                .listRowBackground(TKTheme.surface)
            }
            .tint(TKTheme.brass)
            #if os(iOS)
            .scrollContentBackground(.hidden)
            #endif
            .tkCanvasBackground()
            .navigationTitle(isEditing ? "Edit Watch" : "Add Watch")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(TKTheme.inkSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? TKTheme.brass : TKTheme.inkSecondary)
                }
            }
            .onAppear(perform: load)
            .onChange(of: pickerItem) { _, item in
                Task { await loadPickedPhoto(item) }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 560)
        #endif
    }

    private func load() {
        if let w = existing {
            brand = w.brand
            name = w.name
            reference = w.reference
            status = w.status
            tier = w.tier
            priority = w.priority
            priceText = formatOptional(w.priceTarget)
            pricePaidText = formatOptional(w.pricePaid)
            soldPriceText = formatOptional(w.soldPrice)
            currency = w.currency
            caseSize = w.caseSize
            movement = w.movement
            material = w.material
            retailer = w.retailer
            url = w.url
            notes = w.notes
            photoId = w.photoId
        } else {
            status = defaultStatus
            tier = .highEnd
        }
    }

    private func formatOptional(_ value: Double?) -> String {
        guard let value else { return "" }
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
    }

    private func parsePrice(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: ""))
    }

    @MainActor
    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        if let old = photoId, !PhotoStore.isSeedPhoto(old) {
            PhotoStore.deleteUserPhoto(photoId: old)
        }
        if let saved = try? PhotoStore.saveUserPhoto(data: data) {
            photoId = saved
            photoRefresh = UUID()
        }
    }

    private func save() {
        let price = parsePrice(priceText)
        let paid = parsePrice(pricePaidText)
        let sold = parsePrice(soldPriceText)
        if let w = existing {
            w.brand = brand
            w.name = name
            w.reference = reference
            w.status = status
            w.tier = tier
            w.priority = priority
            w.priceTarget = price
            w.pricePaid = paid
            w.soldPrice = sold
            w.currency = currency.isEmpty ? "USD" : currency
            w.caseSize = caseSize
            w.movement = movement
            w.material = material
            w.retailer = retailer
            w.url = url
            w.notes = notes
            w.photoId = photoId
            w.touch()
        } else {
            let w = Watch(
                brand: brand,
                name: name,
                reference: reference,
                status: status,
                tier: tier,
                priority: priority,
                priceTarget: price,
                pricePaid: paid,
                soldPrice: sold,
                currency: currency.isEmpty ? "USD" : currency,
                caseSize: caseSize,
                movement: movement,
                material: material,
                retailer: retailer,
                url: url,
                notes: notes,
                photoId: photoId
            )
            modelContext.insert(w)
        }
        try? modelContext.save()
        dismiss()
    }
}
