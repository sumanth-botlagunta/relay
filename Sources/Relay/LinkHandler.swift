import AppKit
import RelayCore

@MainActor
enum LinkHandler {
    struct PreparedLink {
        let url: URL
        let originalURL: URL
        let warnings: [SecurityWarning]
        let target: BrowserLauncher.Target?
        let context: String?
    }

    static func handle(rawURL: URL, sourceAppID: String?, forcePicker: Bool = false,
                       context: String? = nil, prioritize: Bool = false) {
        PickerController.shared.enqueue(rawURL: rawURL, sourceAppID: sourceAppID,
            forcePicker: forcePicker, context: context, prioritize: prioritize)
    }

    /// Resolve only when this request reaches the front of the queue, so a rule
    /// saved for an earlier link also applies to later links in the same burst.
    static func prepare(rawURL: URL, sourceAppID: String?, forcePicker: Bool, context: String?) -> PreparedLink? {
        guard URLExtractor.isWebURL(rawURL) else {
            AppFeedback.message("This link has no valid web address", detail: "Relay needs an HTTP or HTTPS link with a website name. Copy a complete link and try again.")
            return nil
        }
        let model = AppModel.shared
        model.registry.refresh()
        let url = model.settings.cleanURLs ? URLCleaner.clean(rawURL) : rawURL
        // Analyze both addresses: choosing the original must not hide its warning.
        let warnings = warnings(original: rawURL, cleaned: url, enabled: model.settings.securityWarnings)
        let decision = LinkRouter.route(
            host: url.host, sourceAppID: sourceAppID, settings: model.settings,
            temporaryDefaultID: model.activeTempBrowserID, isPaused: model.isPaused,
            installed: model.installedIDs, hasWarnings: !warnings.isEmpty, forcePicker: forcePicker)
        let target: BrowserLauncher.Target?
        var message = context
        switch decision {
        case .open(let browserID): target = .browser(browserID)
        case .openChromeProfile(let directory):
            if model.registry.chromeProfiles.contains(where: { $0.directory == directory }) {
                target = .chromeProfile(directory)
            } else {
                target = nil
                message = "The saved Chrome profile is unavailable. Choose a browser."
            }
        case .openChromeIncognito: target = .chromeIncognito
        case .showPicker: target = nil
        }
        if message == nil, let sourceAppID,
           let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: sourceAppID) {
            message = "From " + app.deletingPathExtension().lastPathComponent
        }
        return PreparedLink(url: url, originalURL: rawURL, warnings: warnings, target: target, context: message)
    }

    static func warnings(original: URL, cleaned: URL, enabled: Bool) -> [SecurityWarning] {
        guard enabled else { return [] }
        var result = SecurityAnalyzer.analyze(cleaned)
        for warning in SecurityAnalyzer.analyze(original) where !result.contains(warning) { result.append(warning) }
        return result
    }
}
