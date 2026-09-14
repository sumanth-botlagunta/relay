import Foundation
import RelayCore

func auditRegressionTests() {
    t.run("clipboardDoesNotAppendProseOrSecondURL") {
        for input in ["https://example.com/a please read", "https://example.com/a then https://example.org/b", "https://example.com/a\nhttps://example.org/b"] {
            t.expect(URLExtractor.extractWebURL(from: input)?.absoluteString == "https://example.com/a", input)
        }
        let encoded = "https://example.com/a%20b?q=x%20y"
        t.expect(URLExtractor.extractWebURL(from: encoded)?.absoluteString == encoded)
    }
    t.run("rejectsHostlessWebLinks") {
        for input in ["https:", "https:///missing-host", "https://", "https:example.com"] {
            t.expect(URLExtractor.extractWebURL(from: input) == nil, input)
        }
        t.expect(URLExtractor.isWebURL(URL(string: "https://example.com:8443/path")!))
        t.expect(URLExtractor.isWebURL(URL(string: "http://localhost:8080/")!))
    }
    t.run("warningsAndManualOverrideBeatEveryAutomaticRoute") {
        var settings = Settings()
        settings.primaryBrowserID = "com.apple.Safari"
        settings.rules = [Rule(kind: .sourceApp, pattern: "test.app", browserID: "com.google.Chrome", incognito: true)]
        let warnings = SecurityAnalyzer.analyze(URL(string: "https://trusted.example@example.com/")!)
        t.expect(!warnings.isEmpty)
        for paused in [false, true] {
            for temporary in [nil, "com.google.Chrome"] as [String?] {
                for flags in [(true, false), (false, true)] {
                    let result = LinkRouter.route(host: "example.com", sourceAppID: "test.app", settings: settings,
                        temporaryDefaultID: temporary, isPaused: paused, installed: ["com.apple.Safari", "com.google.Chrome"],
                        hasWarnings: flags.0, forcePicker: flags.1)
                    t.expect(result == .showPicker)
                }
            }
        }
    }
    t.run("exactAndSubdomainRulesRespectDomainBoundaries") {
        let exact = Rule(kind: .domainExact, pattern: " EXAMPLE.com. ", browserID: "browser")
        let subdomains = Rule(kind: .domainAndSubdomains, pattern: "example.com", browserID: "browser")
        t.expect(LinkRouter.matches(exact, host: "example.com", sourceAppID: nil))
        t.expect(!LinkRouter.matches(exact, host: "www.example.com", sourceAppID: nil))
        t.expect(LinkRouter.matches(subdomains, host: "deep.www.example.com", sourceAppID: nil))
        t.expect(LinkRouter.matches(subdomains, host: "example.com.", sourceAppID: nil))
        for host in ["example.com.attacker.test", "notexample.com", "example.company"] {
            t.expect(!LinkRouter.matches(subdomains, host: host, sourceAppID: nil), host)
        }
        for pattern in ["https://example.com", "example.com/path", "example.com:443", "*.example.com", "a..com", ""] {
            t.expect(LinkRouter.normalizedDomain(pattern) == nil, pattern)
        }
        t.expect(LinkRouter.normalizedDomain("café.example")?.hasPrefix("xn--") == true)
    }
    t.run("rememberRulePrecedesBroadMatchAndRoundTripsProfile") {
        var settings = Settings()
        settings.rules = [Rule(kind: .domainContains, pattern: "example", browserID: "com.apple.Safari")]
        settings.remember(Rule(kind: .domainExact, pattern: "example.com", browserID: "com.google.Chrome", profileDirectory: "Profile 1"))
        let restored = try JSONDecoder().decode(Settings.self, from: JSONEncoder().encode(settings))
        let result = LinkRouter.route(host: "example.com", sourceAppID: nil, settings: restored,
            temporaryDefaultID: nil, isPaused: false, installed: ["com.google.Chrome", "com.apple.Safari"])
        t.expect(result == .openChromeProfile(directory: "Profile 1"))
        settings.remember(Rule(kind: .domainExact, pattern: "EXAMPLE.com", browserID: "com.google.Chrome", incognito: true))
        t.expect(settings.rules.count == 2)
        t.expect(LinkRouter.route(host: "example.com", sourceAppID: nil, settings: settings,
            temporaryDefaultID: nil, isPaused: false, installed: ["com.google.Chrome"]) == .openChromeIncognito)
    }
    t.run("missingSettingsFieldsKeepExistingPreferences") {
        let dir = makeAuditDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        var settings = Settings()
        settings.primaryBrowserID = "com.google.Chrome"
        settings.rules = [Rule(kind: .domainContains, pattern: "mail.google.com", browserID: "com.google.Chrome")]
        settings.cleanURLs = false
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(settings)) as! [String: Any]
        for key in ["schemaVersion", "chromeExtras", "pickerModifier", "sendTabShortcut"] { json.removeValue(forKey: key) }
        try JSONSerialization.data(withJSONObject: json).write(to: dir.appendingPathComponent("settings.json"))
        let store = SettingsStore(directory: dir)
        t.expect(store.settings == settings)
        t.expect(store.lastError == nil && store.recoveryURL == nil)
        t.expect(store.settings.rules.first?.kind == .domainContains, "Existing rule semantics must not change")
    }
    t.run("futureSettingsAreNeverOverwritten") {
        let dir = makeAuditDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("settings.json")
        let data = Data("{\"schemaVersion\":999,\"futureSecretSetting\":true}".utf8)
        try data.write(to: file)
        let store = SettingsStore(directory: dir)
        t.expect(store.isReadOnly && store.lastError != nil)
        t.expect(!store.replace(Settings()))
        t.expect(try Data(contentsOf: file) == data)
    }
    t.run("saveFailureIsReportedAndCanRecover") {
        let dir = makeAuditDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = SettingsStore(directory: dir)
        let file = dir.appendingPathComponent("settings.json")
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: true)
        t.expect(!store.replace(Settings()))
        t.expect(store.lastError != nil)
        try FileManager.default.removeItem(at: file)
        t.expect(store.replace(Settings()))
        t.expect(store.lastError == nil)
    }
    t.run("corruptBackupsAreNotClobbered") {
        let dir = makeAuditDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let old = dir.appendingPathComponent("settings.json.corrupt")
        try Data("old backup".utf8).write(to: old)
        try Data("new corrupt data".utf8).write(to: dir.appendingPathComponent("settings.json"))
        let store = SettingsStore(directory: dir)
        t.expect(store.recoveryURL != nil && store.recoveryURL != old)
        t.expect(try String(contentsOf: old, encoding: .utf8) == "old backup")
        t.expect(store.lastError != nil)
    }
}

private func makeAuditDirectory() -> URL {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("relay-regression-\(UUID().uuidString)")
    try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}
