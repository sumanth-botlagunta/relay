import Foundation

// Minimal test harness — CLT has no usable XCTest/Testing runtime.
// Usage: t.run("name") { t.expect(cond, "detail") } ; t.finish() exits 1 on any failure.
final class TestRunner {
    private(set) var passed = 0
    private(set) var failed = 0
    private var currentTest = "?"

    func run(_ name: String, _ body: () throws -> Void) {
        currentTest = name
        do {
            try body()
        } catch {
            failed += 1
            print("✘ \(name): threw \(error)")
        }
    }

    func expect(_ condition: Bool, _ detail: String = "",
                file: StaticString = #filePath, line: UInt = #line) {
        if condition {
            passed += 1
        } else {
            failed += 1
            print("✘ \(currentTest): \(detail.isEmpty ? "expectation failed" : detail)  [\(file):\(line)]")
        }
    }

    func finish() -> Never {
        if failed == 0 {
            print("ALL TESTS PASSED — \(passed) expectations")
            exit(0)
        } else {
            print("TESTS FAILED — \(failed) failed, \(passed) passed")
            exit(1)
        }
    }
}

let t = TestRunner()
