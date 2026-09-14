import Foundation

public struct Browser: Identifiable, Hashable, Codable, Sendable {
    public let bundleID: String
    public let name: String
    public let appURL: URL

    public var id: String { bundleID }

    public init(bundleID: String, name: String, appURL: URL) {
        self.bundleID = bundleID
        self.name = name
        self.appURL = appURL
    }
}

public struct ChromeProfile: Equatable, Sendable {
    public let directory: String
    public let name: String

    public init(directory: String, name: String) {
        self.directory = directory
        self.name = name
    }
}

public enum ChromeProfileParser {
    public static func parse(localStateJSON data: Data) -> [ChromeProfile] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profile = root["profile"] as? [String: Any],
              let cache = profile["info_cache"] as? [String: Any]
        else { return [] }
        return cache.compactMap { key, value -> ChromeProfile? in
            guard let info = value as? [String: Any],
                  let name = info["name"] as? String else { return nil }
            return ChromeProfile(directory: key, name: name)
        }
        .sorted { $0.name < $1.name }
    }
}
