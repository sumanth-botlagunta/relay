import Foundation
import RelayCore

func temporaryDefaultTests() {
    t.run("timedActivationExpires") {
        let temp = TemporaryDefault()
        let start = Date(timeIntervalSince1970: 1_000)
        temp.activate(browserID: "chrome", duration: 3600, now: start)
        t.expect(temp.activeBrowserID(now: start.addingTimeInterval(3599)) == "chrome")
        t.expect(temp.activeBrowserID(now: start.addingTimeInterval(3600)) == nil)
        t.expect(temp.activeBrowserID(now: start) == nil, "expiry should cancel permanently")
    }

    t.run("untilStoppedNeverExpires") {
        let temp = TemporaryDefault()
        let start = Date(timeIntervalSince1970: 1_000)
        temp.activate(browserID: "arc", duration: nil, now: start)
        t.expect(temp.activeBrowserID(now: start.addingTimeInterval(999_999)) == "arc")
        temp.cancel()
        t.expect(temp.activeBrowserID(now: start) == nil)
    }
}
