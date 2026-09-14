import AppKit
import Combine
import RelayCore

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    let registry = BrowserRegistry()
    private let store: SettingsStore
    private let temp = TemporaryDefault()
    private var tempTimer: Timer?
    private var registryObservation: AnyCancellable?
    @Published var persistenceError: String?
    @Published var shortcutError: String?
    var recoveryURL: URL? { store.recoveryURL }
    var preferencesReadOnly: Bool { store.isReadOnly }

    @Published var settings: Settings {
        didSet {
            store.replace(settings)
            persistenceError = store.lastError
        }
    }
    @Published var isPaused = false
    @Published private(set) var tempBrowserID: String?
    @Published private(set) var tempExpiry: Date?

    private init() {
        store = SettingsStore(directory: SettingsStore.defaultDirectory())
        settings = store.settings
        persistenceError = store.lastError
        registry.refresh()
        registryObservation = registry.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }
    }

    func retrySave() {
        store.replace(settings)
        persistenceError = store.lastError
    }

    var installedIDs: Set<String> { Set(registry.browsers.map(\.bundleID)) }

    var activeTempBrowserID: String? {
        let active = temp.activeBrowserID(now: Date())
        if active == nil, tempBrowserID != nil {
            // expired since the last UI update — sync published state
            tempBrowserID = nil
            tempExpiry = nil
        }
        return active
    }

    var primaryBrowser: Browser? {
        registry.browser(withID: LinkRouter.fallbackBrowserID(settings: settings, installed: installedIDs))
    }

    func startTemporary(browserID: String, duration: TimeInterval?) {
        temp.activate(browserID: browserID, duration: duration)
        tempBrowserID = browserID
        tempExpiry = duration.map { Date().addingTimeInterval($0) }
        tempTimer?.invalidate()
        tempTimer = nil
        if let duration {
            tempTimer = Timer.scheduledTimer(withTimeInterval: duration + 1, repeats: false) { _ in
                Task { @MainActor in AppModel.shared.stopTemporary() }
            }
        }
    }

    func stopTemporary() {
        temp.cancel()
        tempBrowserID = nil
        tempExpiry = nil
        tempTimer?.invalidate()
        tempTimer = nil
    }
}
