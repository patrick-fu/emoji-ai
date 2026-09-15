import Foundation
import Carbon
import AppKit

public final class HotKeyManager: @unchecked Sendable {
    public static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var onTrigger: (@Sendable () -> Void)?

    public init() {}

    public func register(combo: HotKeyCombo = .defaultCombo, onTrigger: @escaping @Sendable () -> Void) {
        unregister()
        self.onTrigger = onTrigger

        let hotKeyID = EventHotKeyID(signature: OSType(0x454D4F4A) /* "EMOJ" */, id: 1)
        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            combo.keyCode,
            combo.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            self.hotKeyRef = hotKeyRef
        }

        installEventHandlerIfNeeded()
    }

    public func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            self.hotKeyRef = nil
        }
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handler: EventHandlerUPP = { _, event, userData in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.onTrigger?()
            return noErr
        }

        let ptr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, ptr, &eventHandlerRef)
    }

    deinit {
        unregister()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
    }
}
