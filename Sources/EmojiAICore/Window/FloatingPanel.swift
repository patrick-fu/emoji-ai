import Foundation
import AppKit

@MainActor
public final class FloatingPanel: NSPanel {
    public var onDismiss: (() -> Void)?

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [
                .nonactivatingPanel,
                .titled,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]

        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.hasShadow = true
        self.backgroundColor = .clear
        self.isOpaque = false

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: self
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override public var canBecomeKey: Bool {
        return true
    }

    override public var canBecomeMain: Bool {
        return true
    }

    override public func cancelOperation(_ sender: Any?) {
        dismissPanel()
    }

    override public func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            dismissPanel()
            return
        }
        super.keyDown(with: event)
    }

    @objc private func handleDidResignKey() {
        dismissPanel()
    }

    public func dismissPanel() {
        orderOut(nil)
        onDismiss?()
    }

    public func reposition(screenFrame: NSRect? = nil) {
        let screen = screenFrame ?? (NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900))
        let panelSize = frame.size

        let x = screen.origin.x + (screen.width - panelSize.width) / 2.0
        // Position elevated at ~62% of the screen height (Raycast golden ratio placement)
        let y = screen.origin.y + (screen.height - panelSize.height) * 0.62

        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
