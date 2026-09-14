import Foundation
import RelayCore

private let sampleLocalState = """
{
  "profile": {
    "info_cache": {
      "Default": { "name": "Personal" },
      "Profile 1": { "name": "Work" },
      "Profile 2": { "gaia_id": "x" }
    }
  }
}
""".data(using: .utf8)!

func chromeProfileParserTests() {
    t.run("parsesProfilesSortedByName") {
        let profiles = ChromeProfileParser.parse(localStateJSON: sampleLocalState)
        t.expect(profiles == [
            ChromeProfile(directory: "Default", name: "Personal"),
            ChromeProfile(directory: "Profile 1", name: "Work"),
        ], "got \(profiles)")
    }

    t.run("garbageDataYieldsEmpty") {
        t.expect(ChromeProfileParser.parse(localStateJSON: Data("not json".utf8)) == [])
        t.expect(ChromeProfileParser.parse(localStateJSON: Data("{}".utf8)) == [])
    }
}
