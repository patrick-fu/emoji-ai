import Testing
import Foundation
import AppKit
@testable import EmojiAICore

@Suite("HotKey & AppTarget Tests")
struct HotKeyTests {
    @Test("Test HotKeyCombo formatting and serialization")
    func testHotKeyCombo() throws {
        // Space key code is 49. cmdKey (256), controlKey (4096)
        let combo = HotKeyCombo(keyCode: 49, carbonModifiers: 256 | 4096)
        #expect(combo.keyCode == 49)
        #expect(combo.displayString.contains("Space"))
        #expect(combo.displayString.contains("⌘"))
        #expect(combo.displayString.contains("⌃"))

        let data = try JSONEncoder().encode(combo)
        let decoded = try JSONDecoder().decode(HotKeyCombo.self, from: data)
        #expect(decoded == combo)
    }

    @Test("Test AppTargetTracker tracking frontmost app")
    @MainActor
    func testAppTargetTracker() {
        let tracker = AppTargetTracker()
        tracker.captureCurrentFrontmost()
        let target = tracker.currentTarget
        // In test environment, frontmost application exists (xctest or runner)
        #expect(target != nil)
        #expect(target?.localizedName != nil)
    }
}
