import AppKit

@MainActor
enum DefaultBrowser {
    static func handler(for scheme: String) -> URL? {
        NSWorkspace.shared.urlForApplication(toOpen: URL(string: "\(scheme)://example.com")!)
    }
    static func isDefault(for scheme: String) -> Bool {
        guard let handler = handler(for: scheme) else { return false }
        return handler.standardizedFileURL == Bundle.main.bundleURL.standardizedFileURL
    }
    static var isDefault: Bool { isDefault(for: "http") && isDefault(for: "https") }

    static func request(_ completion: (() -> Void)? = nil) {
        let bundle = Bundle.main.bundleURL
        guard bundle.pathExtension == "app" else {
            AppFeedback.message("Install Relay first", detail: "Default-browser registration requires the installed Relay.app bundle.")
            completion?()
            return
        }
        set(schemes: ["http", "https"], bundle: bundle, completion: completion)
    }

    private static func set(schemes: [String], bundle: URL, completion: (() -> Void)?) {
        guard let scheme = schemes.first else { completion?(); return }
        if isDefault(for: scheme) { set(schemes: Array(schemes.dropFirst()), bundle: bundle, completion: completion); return }
        NSWorkspace.shared.setDefaultApplication(at: bundle, toOpenURLsWithScheme: scheme) { error in
            Task { @MainActor in
                if let error {
                    AppFeedback.message("Default browser was not changed", detail: error.localizedDescription)
                    completion?()
                } else {
                    set(schemes: Array(schemes.dropFirst()), bundle: bundle, completion: completion)
                }
            }
        }
    }
}
