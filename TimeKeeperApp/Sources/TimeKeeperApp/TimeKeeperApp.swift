import SwiftUI
import SwiftData

@main
struct TimeKeeperApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try Persistence.makeContainer(inMemory: false)
        } catch {
            print("TimeKeeper: persistent store failed, falling back to in-memory: \(error)")
            do {
                container = try Persistence.makeContainer(inMemory: true)
            } catch {
                fatalError("TimeKeeper: in-memory store also failed: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        #if os(macOS)
        .defaultSize(width: 1100, height: 720)
        .commands { CommandGroup(replacing: .newItem) {} }
        #endif
    }
}

#if DEBUG
#Preview("Content — seeded") {
    ContentView()
        .modelContainer(Persistence.previewContainer())
}
#endif
