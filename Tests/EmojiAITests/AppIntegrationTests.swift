import Testing
import AppKit
@testable import EmojiAICore

@Suite("AppIntegration Tests")
struct AppIntegrationTests {
    @Test("Test AppDelegate setup and components wiring")
    @MainActor
    func testAppDelegateWiring() async throws {
        let delegate = AppDelegate.shared
        delegate.setupRepositoryAndUI()

        #expect(delegate.panelController != nil)
        #expect(delegate.repository != nil)
        #expect(delegate.viewModel != nil)

        // Verify initial state
        let panel = delegate.panelController?.panel
        #expect(panel?.isFloatingPanel == true)
        #expect(panel?.level == .floating)

        // Verify hotkey trigger flow
        delegate.handleHotKey()
        #expect(panel?.isVisible == true)

        // Toggle to hide
        delegate.togglePanel()
        #expect(panel?.isVisible == false)
    }
}
