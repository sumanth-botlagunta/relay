import Foundation
import RelayCore

func serialLinkQueueTests() {
    t.run("queuedLinksWaitForBrowserLaunchCompletion") {
        var queue = SerialLinkQueue<String>()
        queue.enqueue("picker-first")
        let first = queue.startNext()!
        // Both a rule-routed link and another picker can arrive while the
        // browser for the current request is still launching.
        queue.enqueue("automatic-second")
        queue.enqueue("picker-third")
        t.expect(queue.pendingCount == 2)
        t.expect(queue.startNext() == nil, "Must not display the next picker before launch completes")
        t.expect(queue.active?.value == "picker-first")
        t.expect(queue.complete(id: first.id))
        let second = queue.startNext()!
        t.expect(second.value == "automatic-second")
        t.expect(queue.startNext() == nil)
        t.expect(queue.complete(id: second.id))
        let third = queue.startNext()!
        t.expect(third.value == "picker-third")
        t.expect(queue.pendingCount == 0)
        queue.complete(id: third.id)
        t.expect(queue.startNext() == nil)
    }
    t.run("lateCompletionCannotDismissAnotherLink") {
        var queue = SerialLinkQueue<Int>()
        queue.enqueue(1)
        queue.enqueue(2)
        let first = queue.startNext()!
        queue.complete(id: first.id)
        let second = queue.startNext()!
        t.expect(!queue.complete(id: first.id))
        t.expect(queue.active?.id == second.id)
        t.expect(!queue.complete(id: UUID()))
        t.expect(queue.active?.value == 2)
    }
    t.run("skipKeepsWaitingLinksAndDismissClearsThem") {
        var queue = SerialLinkQueue<Int>()
        for value in 1...4 { queue.enqueue(value) }
        let first = queue.startNext()!
        // Skip completes only the displayed item.
        queue.complete(id: first.id)
        let second = queue.startNext()!
        t.expect(second.value == 2)
        t.expect(queue.pendingCount == 2)
        // Escape/close dismisses the entire current burst.
        queue.dismissPending()
        queue.complete(id: second.id)
        t.expect(queue.pendingCount == 0 && queue.active == nil)
        t.expect(queue.startNext() == nil)
        // A later user click still works.
        queue.enqueue(5)
        t.expect(queue.startNext()?.value == 5)
    }
    t.run("retryWaitsForRecoveryDialogAndPrecedesOtherLinks") {
        var queue = SerialLinkQueue<String>()
        queue.enqueue("failed")
        let first = queue.startNext()!
        queue.enqueue("waiting")
        queue.enqueue("retry-current", prioritize: true)
        t.expect(queue.startNext() == nil, "Recovery dialog still owns the active operation")
        queue.complete(id: first.id)
        let retry = queue.startNext()!
        t.expect(retry.value == "retry-current")
        t.expect(queue.pendingCount == 1)
        queue.complete(id: retry.id)
        t.expect(queue.startNext()?.value == "waiting")
    }
}
