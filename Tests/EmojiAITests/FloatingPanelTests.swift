import Testing
import AppKit
@testable import EmojiAICore

@Suite("FloatingPanel Tests")
struct FloatingPanelTests {
    @Test("Test FloatingPanel configuration and traits")
    @MainActor
    func testFloatingPanelConfiguration() {
        let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 680, height: 440))

        #expect(panel.level == .floating)
        #expect(panel.collectionBehavior.contains(.canJoinAllSpaces))
        #expect(panel.collectionBehavior.contains(.fullScreenAuxiliary))
        #expect(panel.canBecomeKey == true)
        #expect(panel.isFloatingPanel == true)
        #expect(panel.isMovableByWindowBackground == true)
    }

    @Test("Test FloatingPanel positioning on screen")
    @MainActor
    func testPanelPositioning() {
        let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400))
        let mockScreenFrame = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        panel.reposition(screenFrame: mockScreenFrame)

        let frame = panel.frame
        #expect(frame.width == 600)
        #expect(frame.height == 400)
        // Center X = (1920 - 600) / 2 = 660
        #expect(frame.origin.x == 660)
        // Center Y is elevated above mid-screen (y > (1080 - 400) / 2)
        #expect(frame.origin.y > 340)
    }
}
