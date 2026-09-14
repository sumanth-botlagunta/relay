import Foundation

public final class TemporaryDefault {
    private var browserID: String?
    public private(set) var expiry: Date?

    public init() {}

    public func activate(browserID: String, duration: TimeInterval?, now: Date = Date()) {
        self.browserID = browserID
        self.expiry = duration.map { now.addingTimeInterval($0) }
    }

    public func cancel() {
        browserID = nil
        expiry = nil
    }

    public func activeBrowserID(now: Date = Date()) -> String? {
        guard let id = browserID else { return nil }
        if let expiry, now >= expiry {
            cancel()
            return nil
        }
        return id
    }
}
