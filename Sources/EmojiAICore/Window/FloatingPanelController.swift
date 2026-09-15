import Foundation
import AppKit

@MainActor
public final class FloatingPanelController {
    public let panel: FloatingPanel
    public private(set) var targetApp: NSRunningApplication?

    public init(panel: FloatingPanel? = nil) {
        self.panel = panel ?? FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 680, height: 440))
        self.panel.reposition()
    }

    public func show(target: NSRunningApplication? = nil) {
        self.targetApp = target ?? NSWorkspace.shared.frontmostApplication
        panel.reposition()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func hide() {
        panel.dismissPanel()
    }

    public func toggle(target: NSRunningApplication? = nil) {
        if panel.isVisible {
            hide()
        } else {
            show(target: target)
        }
    }
}
