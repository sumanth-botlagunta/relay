import Foundation

public enum RoutingDecision: Equatable, Sendable {
    case open(browserID: String)
    case openChromeProfile(directory: String)
    case openChromeIncognito
    case showPicker
}

public enum LinkRouter {
    public static func route(
        host: String?,
        sourceAppID: String?,
        settings: Settings,
        temporaryDefaultID: String?,
        isPaused: Bool,
        installed: Set<String>,
        hasWarnings: Bool = false,
        forcePicker: Bool = false
    ) -> RoutingDecision {
        let fallback = fallbackBrowserID(settings: settings, installed: installed)

        // A deliberate override and safety warnings always precede automatic routing.
        if hasWarnings || forcePicker { return .showPicker }

        if isPaused {
            return .open(browserID: fallback)
        }
        if let temp = temporaryDefaultID {
            return .open(browserID: installed.contains(temp) ? temp : fallback)
        }
        if let rule = matchingRule(host: host, sourceAppID: sourceAppID, settings: settings, installed: installed) {
            if rule.browserID == "com.google.Chrome" {
                if rule.incognito == true { return .openChromeIncognito }
                if let directory = rule.profileDirectory { return .openChromeProfile(directory: directory) }
            }
            return .open(browserID: rule.browserID)
        }
        return .showPicker
    }

    public static func matchingRule(host: String?, sourceAppID: String?, settings: Settings,
                                    installed: Set<String>) -> Rule? {
        settings.rules.first { rule in
            installed.contains(rule.browserID) && matches(rule, host: host, sourceAppID: sourceAppID)
        }
    }

    public static func matches(_ rule: Rule, host: String?, sourceAppID: String?) -> Bool {
        let pattern = rule.pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pattern.isEmpty else { return false }
        if rule.kind == .sourceApp { return sourceAppID == pattern }
        guard let host else { return false }
        let normalizedHost = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        if rule.kind == .domainContains { return normalizedHost.contains(pattern.lowercased()) }
        guard let domain = normalizedDomain(pattern) else { return false }
        return normalizedHost == domain || (rule.kind == .domainAndSubdomains && normalizedHost.hasSuffix("." + domain))
    }

    public static func normalizedDomain(_ input: String) -> String? {
        let domain = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard !domain.isEmpty, domain.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
              !domain.contains(where: { "/:@?#*%".contains($0) }),
              let url = URL(string: "https://" + domain), let host = url.host,
              !host.isEmpty, !host.contains("..") else { return nil }
        return host.lowercased()
    }

    public static func fallbackBrowserID(settings: Settings, installed: Set<String>) -> String {
        if let primary = settings.primaryBrowserID, installed.contains(primary) {
            return primary
        }
        return "com.apple.Safari"
    }
}
