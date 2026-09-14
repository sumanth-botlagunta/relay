import AppKit
import SwiftUI

@main
struct RelayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel.shared

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            MenuBarLabel(model: model)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { SettingsWindow.show() }.keyboardShortcut(",")
            }
        }
    }
}

struct MenuBarLabel: View {
    @ObservedObject var model: AppModel
    var body: some View {
        Image(systemName: model.isPaused ? "pause.circle" : model.tempBrowserID != nil ? "clock.arrow.circlepath" : "arrow.triangle.branch")
            .accessibilityLabel(model.isPaused ? "Relay paused" : "Relay browser picker")
            .help(model.isPaused ? "Relay — paused" : "Relay — browser picker")
    }
}
