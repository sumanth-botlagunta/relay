import RelayCore

func browserIdentityTests() {
    t.run("Relay cannot be offered as its own browser across release channels") {
        t.expect(BrowserIdentity.isRelay(bundleID: BrowserIdentity.relayBundleID, executableName: nil, bundleName: nil))
        t.expect(BrowserIdentity.isRelay(bundleID: "org.example.legacy", executableName: "Relay", bundleName: "Relay"))
        t.expect(BrowserIdentity.isRelay(bundleID: nil, executableName: "Relay", bundleName: "Relay"))
        t.expect(!BrowserIdentity.isRelay(bundleID: "com.apple.Safari", executableName: "Safari", bundleName: "Safari"))
        t.expect(!BrowserIdentity.isRelay(bundleID: "org.example.browser", executableName: "DifferentBrowser", bundleName: "Relay"))
        t.expect(!BrowserIdentity.isRelay(bundleID: nil, executableName: nil, bundleName: nil))
    }
}
