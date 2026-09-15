import Foundation
import SwiftUI

public struct SettingsView: View {
    @ObservedObject public var settings: SettingsManager
    @State private var testStatus: String?
    @State private var isTesting = false

    public init(settings: SettingsManager = .shared) {
        self.settings = settings
    }

    public var body: some View {
        TabView {
            aiProviderTab
                .tabItem {
                    Label("AI Provider", systemImage: "sparkles")
                }

            shortcutsTab
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 320)
        .padding(20)
    }

    private var aiProviderTab: some View {
        Form {
            Section {
                TextField("Base URL:", text: $settings.aiConfig.baseURL)
                    .textFieldStyle(.roundedBorder)

                SecureField("API Key:", text: $settings.aiConfig.apiKey)
                    .textFieldStyle(.roundedBorder)

                TextField("Model Name:", text: $settings.aiConfig.model)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save Settings") {
                        settings.save()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(isTesting || settings.aiConfig.apiKey.isEmpty)

                    if isTesting {
                        ProgressView().controlSize(.small)
                    }

                    if let status = testStatus {
                        Text(status)
                            .font(.system(size: 11))
                            .foregroundColor(status.contains("Success") ? .green : .red)
                    }
                }
                .padding(.top, 8)
            } footer: {
                Text("Supports any OpenAI-compatible completions endpoint: OpenAI, DeepSeek, Moonshot/Kimi, OpenRouter, or local Ollama.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var shortcutsTab: some View {
        Form {
            Section {
                HStack {
                    Text("Global Activation Shortcut:")
                    Spacer()
                    Text(settings.hotKeyCombo.displayString)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.08))
                        .cornerRadius(6)
                }

                Button("Reset to Default (⌃⌘Space)") {
                    settings.hotKeyCombo = .defaultCombo
                    settings.save()
                }
            } footer: {
                Text("Triggers the floating emoji picker globally without switching window focus.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "face.smiling.inverse")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Emoji AI")
                .font(.title2)
                .bold()

            Text("Version 1.0.0 (Native Swift & SQLite)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider().frame(width: 200)

            Link("GitHub: patrick-fu/emoji-ai", destination: URL(string: "https://github.com/patrick-fu/emoji-ai")!)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func testConnection() {
        isTesting = true
        testStatus = nil

        let service = AIService(config: settings.aiConfig)
        Task {
            do {
                let results = try await service.searchRelevantEmojis(query: "happy")
                await MainActor.run {
                    self.isTesting = false
                    self.testStatus = "Success! (\(results.joined(separator: " ")))"
                    self.settings.save()
                }
            } catch {
                await MainActor.run {
                    self.isTesting = false
                    self.testStatus = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
