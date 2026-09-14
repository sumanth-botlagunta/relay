import AppKit
import ServiceManagement
import SwiftUI
import RelayCore

struct SettingsView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        VStack(spacing: 0) {
            if let error = model.persistenceError {
                VStack(alignment: .leading, spacing: 6) {
                    Label(error, systemImage: "exclamationmark.triangle").font(.callout)
                    HStack {
                        if !model.preferencesReadOnly { Button("Retry Save") { model.retrySave() } }
                        if let backup = model.recoveryURL {
                            Button("Show Recovery File") { NSWorkspace.shared.activateFileViewerSelecting([backup]) }
                        }
                    }
                }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(.orange.opacity(0.15))
            }
            TabView {
                GeneralTab(model: model).tabItem { Label("General", systemImage: "gearshape") }
                RulesTab(model: model).tabItem { Label("Rules", systemImage: "arrow.triangle.branch") }
                BrowsersTab(model: model).tabItem { Label("Browsers", systemImage: "network") }
                DiagnosticsTab(model: model).tabItem { Label("Setup & Help", systemImage: "questionmark.circle") }
            }.disabled(model.preferencesReadOnly)
        }.frame(minWidth: 640, minHeight: 520)
    }
}

struct GeneralTab: View {
    @ObservedObject var model: AppModel
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var isDefaultBrowser = DefaultBrowser.isDefault

    var body: some View {
        Form {
            Section {
                if isDefaultBrowser {
                    Label("Relay is your default browser", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                } else {
                    LabeledContent("Make Relay your default to catch clicked links") {
                        Button("Make Default…") { DefaultBrowser.request { isDefaultBrowser = DefaultBrowser.isDefault } }
                    }
                }
            }
            Picker("Primary browser", selection: $model.settings.primaryBrowserID) {
                Text("Automatic (Safari)").tag(String?.none)
                if let id = model.settings.primaryBrowserID, !model.installedIDs.contains(id) {
                    Text("Not installed (\(id))").tag(Optional(id))
                }
                ForEach(model.registry.browsers) { Text($0.name).tag(Optional($0.bundleID)) }
            }
            Text("Used while paused or when a temporary browser is unavailable. Other links show the picker unless a rule matches.")
                .font(.caption).foregroundStyle(.secondary)
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enable in
                    do {
                        if enable { try SMAppService.mainApp.register() }
                        else { try SMAppService.mainApp.unregister() }
                        if SMAppService.mainApp.status == .requiresApproval {
                            AppFeedback.message("Allow Relay at login", detail: "Approve Relay in System Settings → General → Login Items & Extensions.")
                        }
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                        AppFeedback.message("Login setting could not be changed", detail: error.localizedDescription)
                    }
                }
            Section("Links") {
                Toggle("Remove tracking junk from links", isOn: $model.settings.cleanURLs)
                Toggle("Warn about suspicious links, including automatic routes", isOn: $model.settings.securityWarnings)
            }
            Section("Shortcuts") {
                Picker("Hold while clicking to always show the picker", selection: $model.settings.pickerModifier) {
                    ForEach(PickerModifier.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                Picker("Send current tab / clipboard link", selection: $model.settings.sendTabShortcut) {
                    ForEach(SendTabShortcut.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                if let error = model.shortcutError { Label(error, systemImage: "exclamationmark.triangle").font(.caption) }
            }
        }.formStyle(.grouped)
        .onAppear { refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in refresh() }
    }
    private func refresh() {
        isDefaultBrowser = DefaultBrowser.isDefault
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

struct BrowsersTab: View {
    @ObservedObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Picker entries").font(.headline)
                Spacer()
                Button("Refresh Browsers & Profiles") { model.registry.refresh() }
            }
            Text("Uncheck to hide. Drag to reorder. Apps that handle web links can appear here too.")
                .font(.caption).foregroundStyle(.secondary)
            List {
                ForEach(orderedBrowsers) { browser in
                    HStack {
                        Image(nsImage: model.registry.icon(for: browser)).resizable().frame(width: 24, height: 24)
                        VStack(alignment: .leading) {
                            Text(browser.name)
                            if !BrowserRegistry.isRecognizedBrowser(browser.bundleID) {
                                Text("Other web-link handler").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Toggle("Show \(browser.name)", isOn: visibleBinding(browser)).labelsHidden()
                    }.padding(.vertical, 4)
                }
                .onMove { from, to in
                    var ids = orderedBrowsers.map(\.bundleID)
                    ids.move(fromOffsets: from, toOffset: to)
                    model.settings.browserOrder = ids
                }
            }
            if orderedBrowsers.allSatisfy({ model.settings.hiddenBrowserIDs.contains($0.bundleID) }) {
                Label("All entries are hidden. The picker will let you copy the link or open Settings.", systemImage: "info.circle")
                    .font(.callout)
            }
            Toggle("Show Chrome Incognito and named profiles", isOn: $model.settings.chromeExtras)
        }.padding(16)
    }
    private var orderedBrowsers: [Browser] {
        let byID = Dictionary(uniqueKeysWithValues: model.registry.browsers.map { ($0.bundleID, $0) })
        return model.settings.orderedBrowserIDs(installed: model.registry.browsers.map(\.bundleID)).compactMap { byID[$0] }
    }
    private func visibleBinding(_ browser: Browser) -> Binding<Bool> {
        Binding(get: { !model.settings.hiddenBrowserIDs.contains(browser.bundleID) }, set: {
            if $0 { model.settings.hiddenBrowserIDs.remove(browser.bundleID) }
            else { model.settings.hiddenBrowserIDs.insert(browser.bundleID) }
        })
    }
}

private struct DiagnosticsTab: View {
    @ObservedObject var model: AppModel
    @State private var refreshID = UUID()
    var body: some View {
        Form {
            Section("Installation") {
                LabeledContent("Version", value: RelayVersion.current)
                LabeledContent("Location") { Text(Bundle.main.bundleURL.path).textSelection(.enabled) }
                ForEach(["http", "https"], id: \.self) { scheme in
                    LabeledContent(scheme.uppercased()) {
                        Label(DefaultBrowser.handler(for: scheme)?.deletingPathExtension().lastPathComponent ?? "No handler",
                              systemImage: DefaultBrowser.isDefault(for: scheme) ? "checkmark.circle" : "exclamationmark.circle")
                    }
                }
                HStack {
                    Button("Refresh Status") { refreshID = UUID(); model.registry.refresh() }
                    Button("Test Picker") {
                        LinkHandler.handle(rawURL: URL(string: "https://example.com/?utm_source=relay-test")!, sourceAppID: nil, forcePicker: true, context: "Test link — choose a browser or copy the cleaned URL.")
                    }
                }
            }.id(refreshID)
            Section("Send a tab") {
                Text("Use \(model.settings.sendTabShortcut.label) or the Relay menu. The first request to read a browser tab may ask for Automation permission. If denied, allow Relay in System Settings → Privacy & Security → Automation.")
                Text("If a tab cannot be read, the picker clearly identifies any clipboard link used instead.")
            }
            Section("Picker tips") {
                Text("Arrow keys select a browser; Return opens it. Keys 1–9 open the numbered entry. Escape dismisses all waiting links, Skip moves past one, and Command-C copies the selected original or cleaned URL.")
                Text("“Always use” saves an exact-domain rule for your browser or Chrome profile after a successful launch. Suspicious links still ask first.")
                Text("Hold the modifier selected in General while clicking to override a rule, pause, or temporary default. Some source apps reserve modified clicks for their own actions.")
            }
        }.formStyle(.grouped)
    }
}
