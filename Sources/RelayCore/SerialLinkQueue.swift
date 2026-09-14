import Foundation

/// Keeps the active request reserved until its UI/launch operation actually
/// completes. Requests arriving during asynchronous launches remain pending.
public struct SerialLinkQueue<Value> {
    public struct Item {
        public let id: UUID
        public let value: Value
    }

    public private(set) var active: Item?
    private var pending: [Item] = []
    public var pendingCount: Int { pending.count }

    public init() {}

    public mutating func enqueue(_ value: Value, prioritize: Bool = false) {
        let item = Item(id: UUID(), value: value)
        if prioritize { pending.insert(item, at: 0) }
        else { pending.append(item) }
    }

    public mutating func startNext() -> Item? {
        guard active == nil, !pending.isEmpty else { return nil }
        let next = pending.removeFirst()
        active = next
        return next
    }

    /// Duplicate or delayed completion callbacks must not release another link.
    @discardableResult
    public mutating func complete(id: UUID) -> Bool {
        guard active?.id == id else { return false }
        active = nil
        return true
    }

    public mutating func dismissPending() { pending.removeAll() }
}
