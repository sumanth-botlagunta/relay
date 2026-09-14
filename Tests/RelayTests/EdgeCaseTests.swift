import Foundation
import RelayCore

func edgeCaseTests() {
    // Corrupt/duplicated browserOrder (e.g. interrupted drag-reorder write)
    // must not produce duplicate picker entries — SwiftUI ForEach crashes on
    // duplicate IDs.
    t.run("orderedBrowserIDsDedupes") {
        var s = Settings()
        s.browserOrder = ["b", "b", "a", "b"]
        let ordered = s.orderedBrowserIDs(installed: ["a", "b", "c"])
        t.expect(ordered == ["b", "a", "c"], "got \(ordered)")
    }

    t.run("cleanerKeepsPortAndStripsTrackers") {
        let url = URL(string: "https://example.com:8443/a?utm_source=x&b=1")!
        t.expect(URLCleaner.clean(url).absoluteString == "https://example.com:8443/a?b=1",
                 "got \(URLCleaner.clean(url).absoluteString)")
    }

    t.run("cleanerPreservesEncodedQueryValues") {
        let url = URL(string: "https://example.com/login?next=%2Faccount%2Fbilling&utm_source=mail")!
        let cleaned = URLCleaner.clean(url)
        let items = URLComponents(url: cleaned, resolvingAgainstBaseURL: false)?.queryItems
        t.expect(items?.count == 1)
        t.expect(items?.first?.name == "next")
        t.expect(items?.first?.value == "/account/billing", "got \(String(describing: items))")
    }

    t.run("unwrapCapsAtThreeHops") {
        func wrap(_ s: String) -> String {
            "https://www.google.com/url?q=" +
                s.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        }
        var five = "https://example.com/final"
        for _ in 0..<5 { five = wrap(five) }
        t.expect(URLCleaner.clean(URL(string: five)!).host == "www.google.com",
                 "5 wrappers should not fully unwrap")

        var three = "https://example.com/final"
        for _ in 0..<3 { three = wrap(three) }
        t.expect(URLCleaner.clean(URL(string: three)!).absoluteString == "https://example.com/final")
    }

    t.run("googleUnwrapAlsoAcceptsUrlParam") {
        let url = URL(string: "https://www.google.com/url?url=https%3A%2F%2Fexample.com%2Fx")!
        t.expect(URLCleaner.clean(url).absoluteString == "https://example.com/x")
    }

    t.run("analyzerIsCaseInsensitiveOnHost") {
        t.expect(!SecurityAnalyzer.analyze(URL(string: "https://BIT.LY/abc")!).isEmpty,
                 "uppercase shortener host must still flag")
    }

    t.run("analyzerStacksMultipleWarnings") {
        let url = URL(string: "https://apple.com@xn--pple-43d.com/login")!
        t.expect(SecurityAnalyzer.analyze(url).count == 2,
                 "userinfo + punycode should both fire")
    }

    t.run("extractorPicksFirstOfMultipleURLs") {
        let url = URLExtractor.extractWebURL(from: "see https://first.com/a then https://second.com/b")
        t.expect(url?.host == "first.com", "got \(String(describing: url))")
    }

    t.run("routerHandlesPatternWithStrayWhitespace") {
        var s = Settings()
        s.primaryBrowserID = "com.apple.Safari"
        s.rules = [Rule(kind: .domainContains, pattern: "  meet.google.com  ", browserID: "com.apple.Safari")]
        let d = LinkRouter.route(host: "meet.google.com", sourceAppID: nil, settings: s,
                                 temporaryDefaultID: nil, isPaused: false,
                                 installed: ["com.apple.Safari"])
        t.expect(d == .open(browserID: "com.apple.Safari"))
    }
}
