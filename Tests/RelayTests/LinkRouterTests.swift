import Foundation
import RelayCore

private let safari = "com.apple.Safari"
private let chrome = "com.google.Chrome"
private let arc = "company.thebrowser.Browser"
private let installed: Set<String> = [safari, chrome, arc]

private func settings(_ mutate: (inout Settings) -> Void = { _ in }) -> Settings {
    var s = Settings()
    s.primaryBrowserID = arc
    mutate(&s)
    return s
}

func linkRouterTests() {
    t.run("pausedRoutesToPrimary") {
        let d = LinkRouter.route(host: "example.com", sourceAppID: nil, settings: settings(),
                                 temporaryDefaultID: nil, isPaused: true, installed: installed)
        t.expect(d == .open(browserID: arc))
    }

    t.run("temporaryDefaultWinsOverRules") {
        let s = settings { $0.rules = [Rule(kind: .domainContains, pattern: "example.com", browserID: safari)] }
        let d = LinkRouter.route(host: "example.com", sourceAppID: nil, settings: s,
                                 temporaryDefaultID: chrome, isPaused: false, installed: installed)
        t.expect(d == .open(browserID: chrome))
    }

    t.run("uninstalledTemporaryFallsBack") {
        let d = LinkRouter.route(host: "example.com", sourceAppID: nil, settings: settings(),
                                 temporaryDefaultID: "com.gone.Browser", isPaused: false, installed: installed)
        t.expect(d == .open(browserID: arc))
    }

    t.run("domainRuleMatchesCaseInsensitively") {
        let s = settings { $0.rules = [Rule(kind: .domainContains, pattern: "Meet.Google.com", browserID: chrome)] }
        let d = LinkRouter.route(host: "meet.google.com", sourceAppID: nil, settings: s,
                                 temporaryDefaultID: nil, isPaused: false, installed: installed)
        t.expect(d == .open(browserID: chrome))
    }

    t.run("sourceAppRuleMatches") {
        let s = settings { $0.rules = [Rule(kind: .sourceApp, pattern: "com.tinyspeck.slackmacgap", browserID: chrome)] }
        let d = LinkRouter.route(host: "example.com", sourceAppID: "com.tinyspeck.slackmacgap", settings: s,
                                 temporaryDefaultID: nil, isPaused: false, installed: installed)
        t.expect(d == .open(browserID: chrome))
    }

    t.run("firstMatchingRuleWins") {
        let s = settings { $0.rules = [
            Rule(kind: .domainContains, pattern: "example", browserID: safari),
            Rule(kind: .domainContains, pattern: "example.com", browserID: chrome),
        ] }
        let d = LinkRouter.route(host: "example.com", sourceAppID: nil, settings: s,
                                 temporaryDefaultID: nil, isPaused: false, installed: installed)
        t.expect(d == .open(browserID: safari))
    }

    t.run("ruleWithUninstalledBrowserIsSkipped") {
        let s = settings { $0.rules = [Rule(kind: .domainContains, pattern: "example.com", browserID: "com.gone.Browser")] }
        let d = LinkRouter.route(host: "example.com", sourceAppID: nil, settings: s,
                                 temporaryDefaultID: nil, isPaused: false, installed: installed)
        t.expect(d == .showPicker)
    }

    t.run("emptyPatternNeverMatches") {
        let s = settings { $0.rules = [Rule(kind: .domainContains, pattern: "", browserID: chrome)] }
        let d = LinkRouter.route(host: "example.com", sourceAppID: nil, settings: s,
                                 temporaryDefaultID: nil, isPaused: false, installed: installed)
        t.expect(d == .showPicker)
    }

    t.run("noMatchShowsPicker") {
        let d = LinkRouter.route(host: "example.com", sourceAppID: "com.apple.mail", settings: settings(),
                                 temporaryDefaultID: nil, isPaused: false, installed: installed)
        t.expect(d == .showPicker)
    }

    t.run("nilHostShowsPicker") {
        let d = LinkRouter.route(host: nil, sourceAppID: nil, settings: settings(),
                                 temporaryDefaultID: nil, isPaused: false, installed: installed)
        t.expect(d == .showPicker)
    }

    t.run("fallbackPrefersPrimaryThenSafari") {
        t.expect(LinkRouter.fallbackBrowserID(settings: settings(), installed: installed) == arc)
        t.expect(LinkRouter.fallbackBrowserID(settings: settings(), installed: [safari, chrome]) == safari)
        t.expect(LinkRouter.fallbackBrowserID(settings: Settings(), installed: installed) == safari)
    }
}
