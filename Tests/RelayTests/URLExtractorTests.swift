import Foundation
import RelayCore

func urlExtractorTests() {
    t.run("extractsPlainURL") {
        t.expect(URLExtractor.extractWebURL(from: "https://example.com/a?b=1")?.absoluteString
                 == "https://example.com/a?b=1")
    }

    t.run("trimsWhitespaceAndNewlines") {
        t.expect(URLExtractor.extractWebURL(from: "  https://example.com \n")?.host == "example.com")
    }

    t.run("findsURLInsideText") {
        let url = URLExtractor.extractWebURL(from: "check this out https://news.ycombinator.com/item?id=1 soon")
        t.expect(url?.host == "news.ycombinator.com", "got \(String(describing: url))")
    }

    t.run("rejectsNonURLs") {
        t.expect(URLExtractor.extractWebURL(from: "hello world") == nil)
        t.expect(URLExtractor.extractWebURL(from: "") == nil)
        t.expect(URLExtractor.extractWebURL(from: "   ") == nil)
    }

    t.run("rejectsNonWebSchemes") {
        t.expect(URLExtractor.extractWebURL(from: "file:///tmp/x.html") == nil)
        t.expect(URLExtractor.extractWebURL(from: "ftp://example.com/f") == nil)
    }
}
