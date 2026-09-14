import Foundation

public final class SettingsStore {
    public private(set) var settings = Settings()
    public private(set) var lastError: String?
    public private(set) var recoveryURL: URL?
    public private(set) var isReadOnly = false
    private let fileURL: URL

    public init(directory: URL) {
        fileURL = directory.appendingPathComponent("settings.json")
        load()
    }

    public static func defaultDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Relay", isDirectory: true)
    }

    @discardableResult
    public func replace(_ new: Settings) -> Bool {
        guard !isReadOnly else { return false }
        settings = new
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(settings).write(to: fileURL, options: .atomic)
            lastError = nil
            return true
        } catch {
            lastError = "Your changes could not be saved. \(error.localizedDescription)"
            return false
        }
    }

    private func load() {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch let error as NSError {
            if error.domain != NSCocoaErrorDomain || error.code != NSFileReadNoSuchFileError {
                lastError = "Relay could not read your preferences. \(error.localizedDescription)"
                isReadOnly = true
            }
            return
        }
        // Never overwrite preferences created by a newer app.
        if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let version = root["schemaVersion"] as? Int, version > Settings.currentSchemaVersion {
            lastError = "These preferences need a newer version of Relay. Your saved file has been left untouched."
            isReadOnly = true
            return
        }
        do {
            settings = try JSONDecoder().decode(Settings.self, from: data)
        } catch {
            var backup = fileURL.appendingPathExtension("corrupt")
            if FileManager.default.fileExists(atPath: backup.path) {
                backup = fileURL.appendingPathExtension("\(UUID().uuidString).corrupt")
            }
            do {
                try FileManager.default.moveItem(at: fileURL, to: backup)
                recoveryURL = backup
                lastError = "Relay could not read the saved preferences. Defaults are in use; the original file is preserved for recovery."
            } catch {
                lastError = "Relay could not back up unreadable preferences. Changes will not be saved: \(error.localizedDescription)"
                isReadOnly = true
            }
        }
    }
}
