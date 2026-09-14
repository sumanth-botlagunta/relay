import Foundation
import RelayCore

private func tempDir() -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("relay-tests-\(UUID().uuidString)", isDirectory: true)
    try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

func settingsStoreTests() {
    t.run("roundTripsSettings") {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SettingsStore(directory: dir)
        var s = store.settings
        s.primaryBrowserID = "com.google.Chrome"
        s.rules = [Rule(kind: .domainContains, pattern: "meet.google.com", browserID: "com.google.Chrome")]
        s.cleanURLs = false
        store.replace(s)

        let reloaded = SettingsStore(directory: dir)
        t.expect(reloaded.settings == s, "reloaded settings differ")
    }

    t.run("corruptFileBacksUpAndReturnsDefaults") {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try Data("{{{not json".utf8).write(to: dir.appendingPathComponent("settings.json"))

        let store = SettingsStore(directory: dir)
        t.expect(store.settings == Settings())
        let backup = dir.appendingPathComponent("settings.json.corrupt")
        t.expect(FileManager.default.fileExists(atPath: backup.path), "no .corrupt backup")
    }

    t.run("missingFileReturnsDefaults") {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        t.expect(SettingsStore(directory: dir).settings == Settings())
    }

    t.run("orderedBrowserIDsHonorsOrderThenAppendsRest") {
        var s = Settings()
        s.browserOrder = ["b", "gone", "a"]
        let ordered = s.orderedBrowserIDs(installed: ["a", "b", "c"])
        t.expect(ordered == ["b", "a", "c"], "got \(ordered)")
    }
}
