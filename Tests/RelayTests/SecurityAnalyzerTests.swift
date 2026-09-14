import Foundation
import RelayCore

func securityAnalyzerTests() {
    t.run("flagsUserinfoTrick") {
        let url = URL(string: "https://apple.com@evil.ru/login")!
        let warnings = SecurityAnalyzer.analyze(url)
        t.expect(warnings.count == 1, "got \(warnings)")
        t.expect(warnings.first?.message.contains("evil.ru") == true)
    }

    t.run("flagsPunycodeHost") {
        let url = URL(string: "https://xn--pple-43d.com/")!
        t.expect(!SecurityAnalyzer.analyze(url).isEmpty)
    }

    t.run("flagsRawIPv4AndIPv6") {
        t.expect(!SecurityAnalyzer.analyze(URL(string: "http://192.168.4.7/x")!).isEmpty)
        t.expect(!SecurityAnalyzer.analyze(URL(string: "http://[2001:db8::1]/x")!).isEmpty)
    }

    t.run("flagsKnownShorteners") {
        t.expect(!SecurityAnalyzer.analyze(URL(string: "https://bit.ly/abc")!).isEmpty)
    }

    t.run("benignURLsProduceNoWarnings") {
        t.expect(SecurityAnalyzer.analyze(URL(string: "https://apple.com/mac")!).isEmpty)
        t.expect(SecurityAnalyzer.analyze(URL(string: "https://news.ycombinator.com/item?id=1")!).isEmpty)
        t.expect(SecurityAnalyzer.analyze(URL(string: "https://sub.domain.example.co.in/path")!).isEmpty)
    }

    t.run("hostlessURLProducesNoWarnings") {
        t.expect(SecurityAnalyzer.analyze(URL(string: "file:///tmp/x.html")!).isEmpty)
    }
}
