import AppKit
import RelayCore

@MainActor
enum BrowserLauncher {
    enum Target {
        case browser(String)
        case chromeIncognito
        case chromeProfile(String)

        var bundleID: String {
            switch self {
            case .browser(let id): return id
            case .chromeIncognito, .chromeProfile: return "com.google.Chrome"
            }
        }

        @MainActor func rule(for host: String) -> Rule {
            switch self {
            case .browser(let id): return Rule(kind: .domainExact, pattern: host, browserID: id)
            case .chromeIncognito: return Rule(kind: .domainExact, pattern: host, browserID: BrowserRegistry.chromeBundleID, incognito: true)
            case .chromeProfile(let directory): return Rule(kind: .domainExact, pattern: host, browserID: BrowserRegistry.chromeBundleID, profileDirectory: directory)
            }
        }
    }

    private static var processes: [UUID: Process] = [:]

    static func open(url: URL, target: Target, registry: BrowserRegistry, activate: Bool = true, completion: ((Bool) -> Void)? = nil) {
        let finish: (String?) -> Void = { error in
            // Keep the current link reserved while its recovery dialog is open.
            // A retry is queued before completion releases the next operation.
            if let error { AppFeedback.launchFailed(url: url, detail: error) }
            completion?(error == nil)
        }
        guard URLExtractor.isWebURL(url) else { finish("The address has no valid website."); return }
        switch target {
        case .browser(let id):
            guard id != (Bundle.main.bundleIdentifier ?? BrowserIdentity.relayBundleID),
                  let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) ?? registry.browser(withID: id)?.appURL,
                  FileManager.default.fileExists(atPath: appURL.path),
                  let bundle = Bundle(url: appURL),
                  !BrowserRegistry.isRelayApplication(bundle)
            else { finish("The selected browser is no longer available."); return }
            // Always specify an application: opening with the system default would loop into Relay.
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = activate
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration) { _, error in
                Task { @MainActor in
                    if error != nil { registry.refresh() }
                    finish(error?.localizedDescription)
                }
            }
        case .chromeIncognito:
            shellOpen(["--incognito", url.absoluteString], activate: activate, finish: finish)
        case .chromeProfile(let directory):
            guard registry.chromeProfiles.contains(where: { $0.directory == directory }) else {
                finish("The selected Chrome profile is no longer available."); return
            }
            shellOpen(["--profile-directory=\(directory)", url.absoluteString], activate: activate, finish: finish)
        }
    }

    private static func shellOpen(_ args: [String], activate: Bool, finish: @escaping (String?) -> Void) {
        let id = UUID()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = (activate ? [] : ["-g"]) + ["-nb", BrowserRegistry.chromeBundleID, "--args"] + args
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.terminationHandler = { process in
            Task { @MainActor in
                processes.removeValue(forKey: id)
                finish(process.terminationStatus == 0 ? nil : "Chrome could not open the requested profile or private window (code \(process.terminationStatus)).")
            }
        }
        processes[id] = process
        do { try process.run() }
        catch { processes.removeValue(forKey: id); finish(error.localizedDescription) }
    }
}
