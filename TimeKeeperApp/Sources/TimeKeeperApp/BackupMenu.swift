import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupToolbarMenu: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var watches: [Watch]

    @State private var exportData: Data?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        Menu {
            Button("Export JSON…") { prepareExport() }
            Button("Import JSON…") { showImporter = true }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("Backup and restore")
        .fileExporter(
            isPresented: $showExporter,
            document: exportData.map { JSONFile(data: $0) },
            contentType: .json,
            defaultFilename: "TimeKeeper-backup"
        ) { result in
            switch result {
            case .success:
                alertTitle = "Exported"
                alertMessage = "Backup saved."
                showAlert = true
            case .failure(let error):
                alertTitle = "Export failed"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importFile(url)
            case .failure(let error):
                alertTitle = "Import failed"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func prepareExport() {
        do {
            exportData = try ExportImport.exportJSON(watches: watches)
            showExporter = true
        } catch {
            alertTitle = "Export failed"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func importFile(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let envelope = try ExportImport.decodeEnvelope(from: data)
            let count = try ExportImport.importEnvelope(envelope, into: modelContext)
            alertTitle = "Imported"
            alertMessage = "Updated \(count) watch\(count == 1 ? "" : "es")."
            showAlert = true
        } catch {
            alertTitle = "Import failed"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

struct JSONFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
