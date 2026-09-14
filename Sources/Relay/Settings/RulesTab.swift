import AppKit
import SwiftUI
import UniformTypeIdentifiers
import RelayCore

extension Rule.Kind {
    var label: String {
        switch self {
        case .domainExact: return "Exact domain"
        case .domainAndSubdomains: return "Domain + subdomains"
        case .domainContains: return "Contains (advanced)"
        case .sourceApp: return "Link from app"
        }
    }
}

struct RulesTab: View {
    @ObservedObject var model: AppModel
    @State private var testURL = ""
    @State private var testSource = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Routing rules").font(.headline)
                Spacer()
                Button { model.settings.rules.append(Rule(kind: .domainExact, pattern: "", browserID: model.primaryBrowser?.bundleID ?? BrowserRegistry.safariBundleID)) }
                label: { Label("Add Rule", systemImage: "plus") }
            }
            Text("First matching rule wins. Drag to reorder. Warnings and the picker override always ask first.")
                .font(.caption).foregroundStyle(.secondary)
            if model.settings.rules.isEmpty {
                ContentUnavailableView("No Rules", systemImage: "arrow.triangle.branch",
                    description: Text("Add a rule here, or choose “Always use” when opening a link."))
            } else {
                List {
                    ForEach($model.settings.rules) { $rule in
                        RuleRow(rule: $rule, model: model) {
                            let id = rule.id
                            model.settings.rules.removeAll { $0.id == id }
                        }
                    }
                    .onMove { model.settings.rules.move(fromOffsets: $0, toOffset: $1) }
                }.listStyle(.inset)
            }
            Divider()
            Text("Test a link").font(.headline)
            TextField("https://example.com/page", text: $testURL).textFieldStyle(.roundedBorder)
                .accessibilityLabel("Link to test")
            HStack {
                Text("From app (optional)").font(.caption)
                SourceAppPicker(selection: $testSource)
            }
            Text(preview).font(.callout).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
        }.padding(16)
    }

    private var preview: String {
        guard !testURL.isEmpty else { return "Preview the result without opening a browser." }
        guard let original = URLExtractor.extractWebURL(from: testURL) else { return "Enter a complete web link with a valid website name." }
        let url = model.settings.cleanURLs ? URLCleaner.clean(original) : original
        let warnings = LinkHandler.warnings(original: original, cleaned: url, enabled: model.settings.securityWarnings)
        if !warnings.isEmpty { return "Relay will ask first: this link has a warning." }
        let result = LinkRouter.route(host: url.host, sourceAppID: testSource, settings: model.settings,
            temporaryDefaultID: model.activeTempBrowserID, isPaused: model.isPaused, installed: model.installedIDs)
        let reason = model.isPaused ? "Paused: " : model.tempBrowserID != nil ? "Temporary default: " : ""
        switch result {
        case .showPicker: return "No matching rule. Relay will show the browser picker."
        case .open(let id): return reason + "Opens in " + (model.registry.browser(withID: id)?.name ?? id) + "."
        case .openChromeIncognito: return "Opens in Chrome Incognito."
        case .openChromeProfile(let directory):
            guard let profile = model.registry.chromeProfiles.first(where: { $0.directory == directory }) else {
                return "Saved profile unavailable. Relay will show the browser picker."
            }
            return "Opens in Chrome profile “\(profile.name)”."
        }
    }
}

private struct RuleRow: View {
    @Binding var rule: Rule
    @ObservedObject var model: AppModel
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Picker("Match type", selection: $rule.kind) {
                    ForEach(Rule.Kind.allCases, id: \.self) { Text($0.label).tag($0) }
                }.labelsHidden().frame(width: 165)
                    .onChange(of: rule.kind) { old, new in
                        if (old == .sourceApp) != (new == .sourceApp) { rule.pattern = "" }
                    }
                if rule.kind == .sourceApp {
                    SourceAppPicker(selection: $rule.pattern)
                } else {
                    TextField("example.com", text: $rule.pattern).textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Domain pattern")
                }
                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                Picker("Open in browser", selection: $rule.browserID) {
                    if !model.registry.browsers.contains(where: { $0.bundleID == rule.browserID }) {
                        Text("Not installed (\(rule.browserID))").tag(rule.browserID)
                    }
                    ForEach(model.registry.browsers) { Text($0.name).tag($0.bundleID) }
                }.labelsHidden().frame(width: 150)
                    .onChange(of: rule.browserID) { _, _ in rule.profileDirectory = nil; rule.incognito = nil }
                Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }
                    .buttonStyle(.borderless).help("Delete rule").accessibilityLabel("Delete rule")
            }
            if rule.browserID == BrowserRegistry.chromeBundleID {
                Picker("Chrome destination", selection: destination) {
                    Text("Default profile").tag("default")
                    Text("Incognito").tag("private")
                    if let directory = rule.profileDirectory,
                       !model.registry.chromeProfiles.contains(where: { $0.directory == directory }) {
                        Text("Unavailable profile: \(directory)").tag("profile:" + directory)
                    }
                    ForEach(model.registry.chromeProfiles, id: \.directory) {
                        Text($0.name).tag("profile:" + $0.directory)
                    }
                }.frame(maxWidth: 400)
            }
            if let note {
                Label(note, systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }.padding(.vertical, 6)
    }

    private var destination: Binding<String> {
        Binding(get: {
            if rule.incognito == true { return "private" }
            return rule.profileDirectory.map { "profile:" + $0 } ?? "default"
        }, set: { value in
            rule.incognito = value == "private" ? true : nil
            rule.profileDirectory = value.hasPrefix("profile:") ? String(value.dropFirst(8)) : nil
        })
    }

    private var note: String? {
        if rule.pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Choose an app or enter a domain to activate this rule." }
        if rule.kind == .domainExact || rule.kind == .domainAndSubdomains,
           LinkRouter.normalizedDomain(rule.pattern) == nil { return "Use a domain only, without a scheme, path, port, or wildcard." }
        if !model.registry.browsers.contains(where: { $0.bundleID == rule.browserID }) { return "This rule is skipped until its browser is installed." }
        if let index = model.settings.rules.firstIndex(where: { $0.id == rule.id }),
           model.settings.rules.prefix(index).contains(where: {
               model.installedIDs.contains($0.browserID) &&
               LinkRouter.matches($0, host: rule.kind == .sourceApp ? nil : rule.pattern,
                                  sourceAppID: rule.kind == .sourceApp ? rule.pattern : nil)
           }) { return "An earlier rule also matches this example. Check the order with Test a link." }
        if rule.kind == .domainContains { return "Substring matching also includes unrelated domains containing this text. Exact domain is safer." }
        return nil
    }
}

private struct SourceAppPicker: View {
    @Binding var selection: String
    private var runningApps: [NSRunningApplication] {
        var seen = Set<String>()
        return NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.bundleIdentifier.map { seen.insert($0).inserted } == true
        }.sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }
    var body: some View {
        HStack(spacing: 5) {
            Picker("Source app", selection: $selection) {
                Text("Choose app…").tag("")
                if !selection.isEmpty, !runningApps.contains(where: { $0.bundleIdentifier == selection }) {
                    Text(NSWorkspace.shared.urlForApplication(withBundleIdentifier: selection)?.deletingPathExtension().lastPathComponent ?? selection).tag(selection)
                }
                ForEach(runningApps, id: \.processIdentifier) { Text($0.localizedName ?? $0.bundleIdentifier ?? "App").tag($0.bundleIdentifier ?? "") }
            }.labelsHidden()
            Button { browse() } label: { Image(systemName: "folder") }
                .buttonStyle(.borderless).help("Choose an installed app, including one that is not running")
                .accessibilityLabel("Choose installed source app")
        }
    }
    private func browse() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Choose App"
        if panel.runModal() == .OK, let url = panel.url, let id = Bundle(url: url)?.bundleIdentifier { selection = id }
    }
}
