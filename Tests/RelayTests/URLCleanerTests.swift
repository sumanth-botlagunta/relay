import Foundation
import RelayCore

func urlCleanerTests() {
    t.run("stripsUTMAndKnownTrackers") {
        let url = URL(string: "https://example.com/a?utm_source=x&utm_medium=y&id=5&fbclid=abc")!
        t.expect(URLCleaner.clean(url).absoluteString == "https://example.com/a?id=5",
                 "got \(URLCleaner.clean(url).absoluteString)")
    }

    t.run("removesQueryEntirelyWhenAllTracking") {
        let url = URL(string: "https://example.com/a?gclid=1&utm_campaign=z")!
        t.expect(URLCleaner.clean(url).absoluteString == "https://example.com/a",
                 "got \(URLCleaner.clean(url).absoluteString)")
    }

    t.run("leavesCleanURLsAlone") {
        let url = URL(string: "https://example.com/watch?v=abc&t=42")!
        t.expect(URLCleaner.clean(url) == url)
    }

    t.run("unwrapsGoogleRedirect") {
        let url = URL(string: "https://www.google.com/url?q=https%3A%2F%2Fnews.ycombinator.com%2Fitem%3Fid%3D1&sa=D")!
        t.expect(URLCleaner.clean(url).absoluteString == "https://news.ycombinator.com/item?id=1",
                 "got \(URLCleaner.clean(url).absoluteString)")
    }

    t.run("unwrapsFacebookAndStripsInnerTrackers") {
        let url = URL(string: "https://l.facebook.com/l.php?u=https%3A%2F%2Fexample.com%2Fp%3Futm_source%3Dfb&h=x")!
        t.expect(URLCleaner.clean(url).absoluteString == "https://example.com/p",
                 "got \(URLCleaner.clean(url).absoluteString)")
    }

    t.run("unwrapsSlackRedirect") {
        let url = URL(string: "https://slack-redir.net/link?url=https%3A%2F%2Fexample.com%2Fdoc")!
        t.expect(URLCleaner.clean(url).absoluteString == "https://example.com/doc",
                 "got \(URLCleaner.clean(url).absoluteString)")
    }

    t.run("ignoresNonHTTPUnwrapTargets") {
        let url = URL(string: "https://www.google.com/url?q=javascript%3Aalert(1)")!
        t.expect(URLCleaner.clean(url).host == "www.google.com")
    }

    t.run("unwrapDisabledStillStripsTrackers") {
        let url = URL(string: "https://www.google.com/url?q=https%3A%2F%2Fa.com&utm_source=x")!
        let cleaned = URLCleaner.clean(url, unwrapRedirects: false)
        t.expect(cleaned.host == "www.google.com")
        t.expect(!cleaned.absoluteString.contains("utm_source"))
    }

    t.run("urlWithoutQueryOrHostPassesThrough") {
        let url = URL(string: "https://example.com")!
        t.expect(URLCleaner.clean(url) == url)
    }

    t.run("preservesPercentEncodingOfKeptValueWhenTrackerStripped") {
        let url = URL(string: "https://ex.com/p?q=a%2Bb%26c&utm_source=x")!
        t.expect(URLCleaner.clean(url).absoluteString == "https://ex.com/p?q=a%2Bb%26c",
                 "got \(URLCleaner.clean(url).absoluteString)")
    }

    t.run("stripsPercentEncodedTrackerName") {
        let url = URL(string: "https://ex.com/p?%75tm_source=x&b=1")!
        t.expect(URLCleaner.clean(url).absoluteString == "https://ex.com/p?b=1",
                 "got \(URLCleaner.clean(url).absoluteString)")
    }

    t.run("unwrapsYouTubeRedirect") {
        let url = URL(string: "https://www.youtube.com/redirect?q=https%3A%2F%2Fexample.com%2Fdoc")!
        t.expect(URLCleaner.clean(url).absoluteString == "https://example.com/doc",
                 "got \(URLCleaner.clean(url).absoluteString)")
    }

    t.run("unwrapsInstagramRedirect") {
        let url = URL(string: "https://l.instagram.com/?u=https%3A%2F%2Fexample.com%2Fpost")!
        t.expect(URLCleaner.clean(url).absoluteString == "https://example.com/post",
                 "got \(URLCleaner.clean(url).absoluteString)")
    }

    t.run("doesNotUnwrapYouTubeWatch") {
        let url = URL(string: "https://www.youtube.com/watch?v=abc")!
        t.expect(URLCleaner.clean(url).host == "www.youtube.com",
                 "got \(URLCleaner.clean(url).absoluteString)")
    }

    t.run("ignoresNonHTTPYouTubeRedirectTarget") {
        let url = URL(string: "https://www.youtube.com/redirect?q=javascript%3Aalert(1)")!
        t.expect(URLCleaner.clean(url).host == "www.youtube.com",
                 "got \(URLCleaner.clean(url).absoluteString)")
    }
}
