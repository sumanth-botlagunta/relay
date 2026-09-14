import RelayCore

func smokeTests() {
    t.run("versionIsSet") {
        let parts = RelayVersion.current.split(separator: ".")
        t.expect(parts.count == 3 && parts.allSatisfy { Int($0) != nil },
                 "version should be semver, got \(RelayVersion.current)")
    }
}
