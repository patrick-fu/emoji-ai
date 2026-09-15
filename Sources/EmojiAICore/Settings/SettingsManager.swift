import Foundation
import SwiftUI

@MainActor
public final class SettingsManager: ObservableObject {
    public static let shared = SettingsManager()

    @Published public var aiConfig: AIServiceConfig
    @Published public var hotKeyCombo: HotKeyCombo

    private let defaults: UserDefaults

    private enum Keys {
        static let aiConfig = "emoji.ai.config"
        static let hotKey = "emoji.ai.hotkey"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: Keys.aiConfig),
           let config = try? JSONDecoder().decode(AIServiceConfig.self, from: data) {
            self.aiConfig = config
        } else {
            self.aiConfig = AIServiceConfig()
        }

        if let data = defaults.data(forKey: Keys.hotKey),
           let combo = try? JSONDecoder().decode(HotKeyCombo.self, from: data) {
            self.hotKeyCombo = combo
        } else {
            self.hotKeyCombo = .defaultCombo
        }
    }

    public func save() {
        if let aiData = try? JSONEncoder().encode(aiConfig) {
            defaults.set(aiData, forKey: Keys.aiConfig)
        }
        if let hotKeyData = try? JSONEncoder().encode(hotKeyCombo) {
            defaults.set(hotKeyData, forKey: Keys.hotKey)
        }
    }
}
