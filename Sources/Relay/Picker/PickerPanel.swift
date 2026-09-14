import AppKit
import Combine
import SwiftUI
import RelayCore

final class PickerPanel: NSPanel {
    private let vm: PickerViewModel
    private let onChoice: (PickerChoice) -> Void
    private var finished = false
    private var observation: AnyCancellable?

    @MainActor
    init(vm: PickerViewModel, onChoice: @escaping (PickerChoice) -> Void) {
        self.vm = vm
        self.onChoice = onChoice
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .popUpMenu
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let hosting = NSHostingView(rootView: PickerView(vm: vm) { [weak self] in self?.finish($0) })
        // The panel owns its size and screen clamping. Letting the hosting view
        // resize the window first can grow expanded details beyond the screen.
        hosting.sizingOptions = []
        hosting.autoresizingMask = [.width, .height]
        contentView = hosting
        setContentSize(NSSize(width: vm.width, height: vm.height))
        contentView?.setFrameSize(NSSize(width: vm.width, height: vm.height))
        observation = vm.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async { self?.resizeToFit() }
        }
    }

    override var canBecomeKey: Bool { true }

    @MainActor
    func present() {
        let mouse = NSEvent.mouseLocation
        setFrameOrigin(NSPoint(x: mouse.x - frame.width / 2, y: mouse.y - frame.height - 12))
        clampToScreen()
        makeKeyAndOrderFront(nil)
    }

    private func resizeToFit() {
        guard !finished else { return }
        let top = frame.maxY
        setContentSize(NSSize(width: vm.width, height: vm.height))
        contentView?.setFrameSize(NSSize(width: vm.width, height: vm.height))
        setFrameOrigin(NSPoint(x: frame.minX, y: top - frame.height))
        clampToScreen()
    }

    private func clampToScreen() {
        let visible = screen?.visibleFrame ?? NSScreen.screens.first {
            NSMouseInRect(NSEvent.mouseLocation, $0.frame, false)
        }?.visibleFrame ?? NSScreen.main?.visibleFrame
        guard let visible else { return }
        setFrameOrigin(NSPoint(
            x: max(visible.minX + 8, min(frame.minX, visible.maxX - frame.width - 8)),
            y: max(visible.minY + 8, min(frame.minY, visible.maxY - frame.height - 8))))
    }

    private func finish(_ choice: PickerChoice) {
        guard !finished else { return }
        finished = true
        // Close the old panel before a queued panel can become key.
        close()
        onChoice(choice)
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: finish(.cancel)
        case 36, 76:
            if vm.entries.indices.contains(vm.selection) { finish(.open(vm.entries[vm.selection])) }
        case 123, 126:
            if !vm.entries.isEmpty { vm.selection = (vm.selection + vm.entries.count - 1) % vm.entries.count }
        case 124, 125:
            if !vm.entries.isEmpty { vm.selection = (vm.selection + 1) % vm.entries.count }
        default:
            let modifiers = event.modifierFlags.intersection([.command, .control, .option])
            if modifiers.isEmpty, let char = event.charactersIgnoringModifiers?.first,
               let n = char.wholeNumberValue, (1...9).contains(n), n <= vm.entries.count {
                finish(.open(vm.entries[n - 1]))
            } else { super.keyDown(with: event) }
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers?.lowercased() == "c" {
            finish(.copy)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func resignKey() {
        super.resignKey()
        finish(.deactivate)
    }
}

@MainActor
final class PickerController {
    static let shared = PickerController()
    private var panel: PickerPanel?
    private var viewModel: PickerViewModel?
    private var lastOpenedBrowserID: String?
    private struct Request {
        let rawURL: URL
        let sourceAppID: String?
        let forcePicker: Bool
        let context: String?
    }
    private var queue = SerialLinkQueue<Request>()

    func enqueue(rawURL: URL, sourceAppID: String?, forcePicker: Bool, context: String?, prioritize: Bool = false) {
        queue.enqueue(Request(rawURL: rawURL, sourceAppID: sourceAppID, forcePicker: forcePicker, context: context), prioritize: prioritize)
        viewModel?.pendingCount = queue.pendingCount
        presentNext()
    }

    private func presentNext() {
        guard queue.active == nil else { return }
        guard let item = queue.startNext() else {
            if let id = lastOpenedBrowserID {
                lastOpenedBrowserID = nil
                NSRunningApplication.runningApplications(withBundleIdentifier: id).first?
                    .activate(options: [])
            }
            return
        }
        let request = item.value
        guard let link = LinkHandler.prepare(rawURL: request.rawURL, sourceAppID: request.sourceAppID,
            forcePicker: request.forcePicker, context: request.context) else {
            complete(item.id)
            return
        }
        let model = AppModel.shared
        if let target = link.target {
            BrowserLauncher.open(url: link.url, target: target, registry: model.registry, activate: false) { success in
                if success { self.lastOpenedBrowserID = target.bundleID }
                self.complete(item.id)
            }
            return
        }
        let vm = PickerViewModel(entries: PickerEntry.build(model: model), url: link.url,
            originalURL: link.originalURL, warnings: link.warnings, context: link.context)
        vm.pendingCount = queue.pendingCount
        viewModel = vm
        let newPanel = PickerPanel(vm: vm) { choice in
            self.panel = nil
            self.viewModel = nil
            switch choice {
            case .open(let entry):
                let url = vm.url
                let remember = vm.rememberDomain
                BrowserLauncher.open(url: url, target: entry.target, registry: model.registry, activate: false) { success in
                    if success { self.lastOpenedBrowserID = entry.target.bundleID }
                    if success, remember, let host = url.host {
                        model.settings.remember(entry.target.rule(for: host))
                    }
                    // Do not present the next picker while this browser is still launching.
                    self.complete(item.id)
                }
            case .copy:
                AppFeedback.copy(vm.url)
                self.complete(item.id)
            case .skip:
                self.complete(item.id)
            case .settings:
                self.queue.dismissPending()
                self.lastOpenedBrowserID = nil
                SettingsWindow.show()
                self.complete(item.id)
            case .cancel:
                self.queue.dismissPending()
                self.complete(item.id)
            case .deactivate:
                // Respect an intentional switch to another app; don't pull the
                // user back to a browser after clicking away from the picker.
                self.lastOpenedBrowserID = nil
                self.queue.dismissPending()
                self.complete(item.id)
            }
        }
        panel = newPanel
        newPanel.present()
    }

    private func complete(_ id: UUID) {
        guard queue.complete(id: id) else { return }
        DispatchQueue.main.async { self.presentNext() }
    }
}
