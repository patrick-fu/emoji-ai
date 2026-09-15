import Foundation
import AppKit

@MainActor
public final class AppTargetTracker {
    public private(set) var currentTarget: NSRunningApplication?

    public init() {}

    public func captureCurrentFrontmost() {
        let front = NSWorkspace.shared.frontmostApplication
        if let front = front, front.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            self.currentTarget = front
        } else if self.currentTarget == nil {
            self.currentTarget = front
        }
    }

    public func activateTarget() {
        currentTarget?.activate()
    }
}
