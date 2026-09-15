import Testing
import Foundation
@testable import EmojiAICore

@Suite("SettingsManager Tests")
struct SettingsManagerTests {
    @Test("Test SettingsManager loading and saving config")
    @MainActor
    func testSettingsPersistence() {
        let userDefaults = UserDefaults(suiteName: "test.emoji.ai.settings")!
        userDefaults.removePersistentDomain(forName: "test.emoji.ai.settings")

        let manager = SettingsManager(defaults: userDefaults)

        #expect(manager.aiConfig.baseURL == "https://api.openai.com/v1")
        #expect(manager.aiConfig.model == "gpt-4o-mini")

        // Update config
        manager.aiConfig.baseURL = "https://api.deepseek.com/v1"
        manager.aiConfig.apiKey = "sk-custom-secret"
        manager.aiConfig.model = "deepseek-chat"
        manager.save()

        // Create new instance with same defaults to verify persistence
        let reloaded = SettingsManager(defaults: userDefaults)
        #expect(reloaded.aiConfig.baseURL == "https://api.deepseek.com/v1")
        #expect(reloaded.aiConfig.apiKey == "sk-custom-secret")
        #expect(reloaded.aiConfig.model == "deepseek-chat")
    }
}
