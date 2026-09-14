import Foundation

public struct Rule: Codable, Equatable, Identifiable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        case domainExact
        case domainAndSubdomains
        case domainContains
        case sourceApp
    }

    public var id: UUID
    public var kind: Kind
    public var pattern: String
    public var browserID: String
    public var profileDirectory: String?
    public var incognito: Bool?

    public init(id: UUID = UUID(), kind: Kind, pattern: String, browserID: String,
                profileDirectory: String? = nil, incognito: Bool? = nil) {
        self.id = id
        self.kind = kind
        self.pattern = pattern
        self.browserID = browserID
        self.profileDirectory = profileDirectory
        self.incognito = incognito
    }
}

public struct Settings: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 2
    public var schemaVersion = Settings.currentSchemaVersion
    public var primaryBrowserID: String?
    public var rules: [Rule] = []
    public var hiddenBrowserIDs: Set<String> = []
    public var browserOrder: [String] = []
    public var cleanURLs: Bool = true
    public var securityWarnings: Bool = true
    public var chromeExtras: Bool = true
    public var pickerModifier: PickerModifier = .option
    public var sendTabShortcut: SendTabShortcut = .controlOptionB

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, primaryBrowserID, rules, hiddenBrowserIDs, browserOrder
        case cleanURLs, securityWarnings, chromeExtras, pickerModifier, sendTabShortcut
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let version = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        guard version <= Self.currentSchemaVersion else {
            throw DecodingError.dataCorruptedError(forKey: .schemaVersion, in: c,
                debugDescription: "These preferences need a newer version of Relay.")
        }
        primaryBrowserID = try c.decodeIfPresent(String.self, forKey: .primaryBrowserID)
        rules = try c.decodeIfPresent([Rule].self, forKey: .rules) ?? []
        hiddenBrowserIDs = try c.decodeIfPresent(Set<String>.self, forKey: .hiddenBrowserIDs) ?? []
        browserOrder = try c.decodeIfPresent([String].self, forKey: .browserOrder) ?? []
        cleanURLs = try c.decodeIfPresent(Bool.self, forKey: .cleanURLs) ?? true
        securityWarnings = try c.decodeIfPresent(Bool.self, forKey: .securityWarnings) ?? true
        chromeExtras = try c.decodeIfPresent(Bool.self, forKey: .chromeExtras) ?? true
        pickerModifier = try c.decodeIfPresent(PickerModifier.self, forKey: .pickerModifier) ?? .option
        sendTabShortcut = try c.decodeIfPresent(SendTabShortcut.self, forKey: .sendTabShortcut) ?? .controlOptionB
    }

    /// A picker-created rule must take precedence over existing broad rules.
    public mutating func remember(_ rule: Rule) {
        rules.removeAll { $0.kind == rule.kind &&
            $0.pattern.caseInsensitiveCompare(rule.pattern) == .orderedSame }
        rules.insert(rule, at: 0)
    }

    public func orderedBrowserIDs(installed: [String]) -> [String] {
        var result: [String] = []
        for id in browserOrder where installed.contains(id) && !result.contains(id) {
            result.append(id)
        }
        for id in installed where !result.contains(id) {
            result.append(id)
        }
        return result
    }
}

public enum PickerModifier: String, Codable, CaseIterable, Sendable {
    case option, shift, disabled
    public var label: String {
        switch self { case .option: return "Option (⌥)"; case .shift: return "Shift (⇧)"; case .disabled: return "Off" }
    }
}

public enum SendTabShortcut: String, Codable, CaseIterable, Sendable {
    case controlOptionB, controlOptionL, controlOptionR, disabled
    public var label: String {
        switch self {
        case .controlOptionB: return "⌃⌥B"
        case .controlOptionL: return "⌃⌥L"
        case .controlOptionR: return "⌃⌥R"
        case .disabled: return "Off"
        }
    }
}
