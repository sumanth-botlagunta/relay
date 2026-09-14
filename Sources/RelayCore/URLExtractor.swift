import Foundation

public enum URLExtractor {
    /// Pulls the first web (http/https) URL out of arbitrary text — a bare
    /// URL, a URL with surrounding words, or clipboard junk. Nil if none.
    public static func extractWebURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
           let direct = URL(string: trimmed), direct.scheme != nil {
            // Do not let link detection "repair" an explicitly malformed URL
            // (https:example.com) by extracting only its domain.
            return isWebURL(direct) ? direct : nil
        }

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        else { return nil }
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        for match in detector.matches(in: trimmed, range: range) {
            if let url = match.url, isWebURL(url) {
                return url
            }
        }
        return nil
    }

    public static func isWebURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              let host = url.host, !host.isEmpty,
              host.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
        else { return false }
        return scheme == "http" || scheme == "https"
    }
}
