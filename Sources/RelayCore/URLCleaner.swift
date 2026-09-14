import Foundation

public enum URLCleaner {
    static let trackingPrefixes = ["utm_"]
    static let trackingParams: Set<String> = [
        "fbclid", "gclid", "dclid", "msclkid", "mc_eid", "mc_cid",
        "igshid", "igsh", "yclid", "twclid", "vero_id", "wickedid",
        "_hsenc", "_hsmi", "mkt_tok", "gbraid", "wbraid",
    ]

    public static func clean(_ url: URL, unwrapRedirects: Bool = true) -> URL {
        var current = url
        if unwrapRedirects {
            var hops = 0
            while hops < 3, let unwrapped = unwrap(current) {
                current = unwrapped
                hops += 1
            }
        }
        return stripTracking(current)
    }

    static func stripTracking(_ url: URL) -> URL {
        guard var comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = comps.queryItems, !items.isEmpty,
              let encodedItems = comps.percentEncodedQueryItems,
              encodedItems.count == items.count
        else { return url }
        // Match tracker names against the DECODED names (so an encoded name like
        // %75tm_source is still recognized), but keep the original
        // percent-encoded items so surviving values are preserved byte-for-byte.
        var kept: [URLQueryItem] = []
        for (index, item) in items.enumerated() {
            let name = item.name.lowercased()
            if trackingParams.contains(name) { continue }
            if trackingPrefixes.contains(where: { name.hasPrefix($0) }) { continue }
            kept.append(encodedItems[index])
        }
        guard kept.count != items.count else { return url }
        comps.percentEncodedQueryItems = kept.isEmpty ? nil : kept
        return comps.url ?? url
    }

    static func unwrap(_ url: URL) -> URL? {
        guard let host = url.host?.lowercased(),
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }

        func param(_ name: String) -> URL? {
            guard let value = comps.queryItems?.first(where: { $0.name == name })?.value,
                  let inner = URL(string: value),
                  let scheme = inner.scheme?.lowercased(),
                  scheme == "http" || scheme == "https", URLExtractor.isWebURL(inner)
            else { return nil }
            return inner
        }

        switch host {
        case "google.com", "www.google.com":
            if url.path == "/url" { return param("q") ?? param("url") }
        case "l.facebook.com", "lm.facebook.com":
            if url.path == "/l.php" { return param("u") }
        case "slack-redir.net", "www.slack-redir.net":
            if url.path == "/link" { return param("url") }
        case "out.reddit.com":
            return param("url")
        case "www.youtube.com", "youtube.com", "m.youtube.com":
            if url.path == "/redirect" { return param("q") }
        case "l.instagram.com":
            return param("u")
        default:
            break
        }
        return nil
    }
}
