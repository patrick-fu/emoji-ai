import Testing
import AppKit
@testable import EmojiAICore

@Suite("PasteManager Tests")
struct PasteManagerTests {
    @Test("Test copying text with Transient Pasteboard types")
    @MainActor
    func testTransientPasteboardCopy() {
        let pasteManager = PasteManager()
        let emoji = "🎉"

        pasteManager.copyTransient(text: emoji)

        let pb = NSPasteboard.general
        let stringContent = pb.string(forType: .string)
        #expect(stringContent == emoji)

        let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
        let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

        #expect(pb.types?.contains(transientType) == true)
        #expect(pb.types?.contains(concealedType) == true)
    }
}
