import Foundation

public struct SecurityWarning: Equatable, Sendable {
    public let message: String
    public init(_ message: String) { self.message = message }
}

public enum SecurityAnalyzer {
    static let shorteners: Set<String> = [
        "bit.ly", "tinyurl.com", "t.co", "goo.gl", "ow.ly", "is.gd",
        "buff.ly", "rebrand.ly", "cutt.ly", "shorturl.at", "rb.gy", "t.ly",
    ]

    public static func analyze(_ url: URL) -> [SecurityWarning] {
        guard let host = url.host?.lowercased() else { return [] }
        var warnings: [SecurityWarning] = []

        if url.user != nil || url.password != nil {
            warnings.append(.init("Address hides its real destination — actually goes to “\(host)”"))
        }
        // IDN hosts are stored punycoded, so this also catches mixed-script homographs.
        if host.contains("xn--") {
            warnings.append(.init("Lookalike (punycode) domain — may imitate a well-known site"))
        }
        if isIPAddress(host) {
            warnings.append(.init("Link points to a raw IP address, not a named website"))
        }
        if shorteners.contains(host) {
            warnings.append(.init("Shortened link — final destination unknown"))
        }
        return warnings
    }

    static func isIPAddress(_ host: String) -> Bool {
        let bare = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        var v4 = in_addr()
        var v6 = in6_addr()
        return bare.withCString { cs in
            inet_pton(AF_INET, cs, &v4) == 1 || inet_pton(AF_INET6, cs, &v6) == 1
        }
    }
}
