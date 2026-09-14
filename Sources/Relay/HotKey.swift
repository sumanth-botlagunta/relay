import Carbon.HIToolbox
import Foundation

/// Global hotkey via the Carbon RegisterEventHotKey API — works from an
/// accessory app with no Accessibility permission (unlike NSEvent monitors).
final class HotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let handler: () -> Void

    init?(keyCode: UInt32, carbonModifiers: UInt32, handler: @escaping () -> Void) {
        self.handler = handler

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, _, userData in
            guard let userData else { return noErr }
            Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue().handler()
            return noErr
        }
        guard InstallEventHandler(GetApplicationEventTarget(), callback, 1, &eventType,
                                  Unmanaged.passUnretained(self).toOpaque(), &handlerRef) == noErr
        else { return nil }

        let hotKeyID = EventHotKeyID(signature: OSType(0x52454C59), id: 1)  // 'RELY'
        guard RegisterEventHotKey(keyCode, carbonModifiers, hotKeyID,
                                  GetApplicationEventTarget(), 0, &hotKeyRef) == noErr
        else {
            if let handlerRef { RemoveEventHandler(handlerRef) }
            handlerRef = nil
            return nil
        }
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
