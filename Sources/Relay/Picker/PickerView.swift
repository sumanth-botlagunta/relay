import SwiftUI
import RelayCore

struct PickerView: View {
    @ObservedObject var vm: PickerViewModel
    let choose: (PickerChoice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Open link with", systemImage: "arrow.triangle.branch")
                    .font(.headline)
                Spacer()
                if vm.pendingCount > 0 {
                    Text("\(vm.pendingCount + 1) links").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        .accessibilityLabel(vm.pendingCount == 1 ? "1 more link waiting" : "\(vm.pendingCount) more links waiting")
                }
                Button { choose(.cancel) } label: { Image(systemName: "xmark") }
                    .buttonStyle(.plain).help("Dismiss all waiting links (Escape)").accessibilityLabel(vm.pendingCount > 0 ? "Dismiss All Links" : "Cancel")
            }
            Text(vm.host).font(.subheadline.weight(.semibold)).lineLimit(2).help(vm.host)
            if let context = vm.context {
                Text(context).font(.caption).foregroundStyle(.secondary).lineLimit(2).help(context)
            }
            if vm.pendingCount > 0 {
                Text("Links open in the background while you choose.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if !vm.warnings.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(vm.warnings, id: \.message) { warning in
                            Label(warning.message, systemImage: "exclamationmark.triangle.fill")
                                .font(.callout).fixedSize(horizontal: false, vertical: true)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 70).padding(8)
                .foregroundStyle(.primary)
                .background(Color.orange.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Check this link before opening")
            }
            Button {
                vm.showDetails.toggle()
            } label: {
                Label(vm.showDetails ? "Hide link details" : "Show full link", systemImage: vm.showDetails ? "chevron.up" : "chevron.down")
                    .font(.caption)
            }.buttonStyle(.plain)
            if vm.showDetails {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Will open").font(.caption.weight(.semibold))
                        Text(vm.url.absoluteString).font(.caption.monospaced()).textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        if vm.originalURL != vm.cleanedURL {
                            Toggle("Open original link instead", isOn: $vm.useOriginal).font(.caption)
                            Text(vm.useOriginal ? "The original link may include tracking or redirects." : "Tracking parameters or redirects were removed.")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("Original: " + vm.originalURL.absoluteString).font(.caption.monospaced())
                                .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.frame(height: 128)
            }
            Divider()
            if vm.entries.isEmpty {
                VStack(spacing: 8) {
                    Text("No visible browsers").font(.headline)
                    Text("Enable a browser in Settings, then try the link again. You can also copy it below.")
                        .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Open Settings") { choose(.settings) }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 3) {
                            ForEach(Array(vm.entries.enumerated()), id: \.element.id) { index, entry in
                                EntryButton(entry: entry, index: index, vm: vm, choose: choose)
                                .id(index)
                            }
                        }
                    }
                    .onChange(of: vm.selection) { _, index in proxy.scrollTo(index) }
                }.frame(maxHeight: .infinity)
            }
            Divider()
            if !vm.entries.isEmpty {
                Toggle("Always use my choice for this exact domain", isOn: $vm.rememberDomain)
                    .font(.caption)
                    .disabled(LinkRouter.normalizedDomain(vm.host) == nil)
                    .help("Adds a rule for \(vm.host). Suspicious links will still ask first.")
            }
            HStack {
                Button("Copy Link") { choose(.copy) }.buttonStyle(.borderless)
                    .help("Copy the selected original or cleaned address (⌘C)")
                if vm.pendingCount > 0 {
                    Button("Skip") { choose(.skip) }.buttonStyle(.borderless)
                        .help("Skip this link and continue to the next")
                }
                Spacer()
                Text("↑↓ select · ↵ open · 1–9").font(.caption2).foregroundStyle(.secondary)
            }
            Text(vm.pendingCount > 0 ? "Esc dismisses all · ⌘C copies this link" : "Esc to cancel · ⌘C to copy").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: vm.width, height: vm.height)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.separator, lineWidth: 0.5))
    }
}

private struct EntryRow: View {
    let entry: PickerEntry
    let index: Int
    let selected: Bool
    let hovered: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: entry.icon).resizable().frame(width: 30, height: 30)
                .overlay(alignment: .bottomTrailing) {
                    if let badge = entry.badge {
                        Image(systemName: badge).font(.system(size: 12, weight: .bold))
                            .padding(2).background(.background, in: Circle()).offset(x: 5, y: 3)
                    }
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title).font(.system(size: 13, weight: .medium)).lineLimit(1)
                if !entry.subtitle.isEmpty { Text(entry.subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1) }
            }
            Spacer(minLength: 6)
            if index < 9 {
                Text("\(index + 1)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    .frame(width: 21, height: 23).background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
            }
        }
        .padding(.horizontal, 10).frame(height: 49).frame(maxWidth: .infinity, alignment: .leading)
        .background(selected ? Color.accentColor.opacity(0.18) : hovered ? Color.primary.opacity(0.06) : .clear, in: RoundedRectangle(cornerRadius: 9))
        .contentShape(Rectangle())
    }
}

private struct EntryButton: View {
    let entry: PickerEntry
    let index: Int
    @ObservedObject var vm: PickerViewModel
    @State private var hovered = false
    let choose: (PickerChoice) -> Void
    private var accessibleName: String { entry.title + (entry.subtitle.isEmpty ? "" : ", " + entry.subtitle) }
    var body: some View {
        Button { choose(.open(entry)) } label: {
            EntryRow(entry: entry, index: index, selected: index == vm.selection, hovered: hovered)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibleName))
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(Text(index == vm.selection ? "Selected" : ""))
        .accessibilityHint(Text(index < 9 ? "Open link, shortcut \(index + 1)" : "Open link"))
        .help(Text(accessibleName))
        // Hover gives mouse feedback without stealing the keyboard selection
        // when a panel appears, expands, or scrolls under a stationary pointer.
        .onHover { hovered = $0 }
    }
}
