import SwiftUI

@main
struct BrowserAgentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .sidebar) {
                Button("Показати вибір моделі") {
                    // Тут потрібно додати логіку для відображення селектора моделі
                }
                .keyboardShortcut("m", modifiers: [.command])
            }
        }
    }
} 