/// Recognizes this app across release channels without recording legacy personal identifiers.
public enum BrowserIdentity {
    public static let relayBundleID = "org.relaybrowser.Relay"

    public static func isRelay(bundleID: String?, executableName: String?, bundleName: String?) -> Bool {
        bundleID == relayBundleID || (executableName == "Relay" && bundleName == "Relay")
    }
}
