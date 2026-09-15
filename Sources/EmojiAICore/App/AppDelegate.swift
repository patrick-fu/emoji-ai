import Foundation
import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static let shared = AppDelegate()

    private var statusItem: NSStatusItem?
    public private(set) var panelController: FloatingPanelController?
    public private(set) var repository: EmojiRepository?
    public private(set) var viewModel: EmojiPickerViewModel?
    private let targetTracker = AppTargetTracker()

    override public init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupRepositoryAndUI()
        setupStatusItem()
        setupHotKey()
    }

    public func setupRepositoryAndUI() {
        do {
            let repo = try EmojiRepository()
            self.repository = repo

            let settings = SettingsManager.shared
            let aiService = AIService(config: settings.aiConfig)
            let vm = EmojiPickerViewModel(repository: repo, aiService: aiService)
            self.viewModel = vm

            let rootView = EmojiPickerView(viewModel: vm)
            let hostingView = NSHostingView(rootView: rootView)

            let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 680, height: 440))
            panel.contentView = hostingView
            self.panelController = FloatingPanelController(panel: panel)

            vm.onSelectEmoji = { [weak self] emoji in
                guard let self = self else { return }
                self.panelController?.hide()
                let target = self.targetTracker.currentTarget
                Task {
                    await PasteManager.shared.paste(text: emoji, to: target)
                }
            }

            vm.onClose = { [weak self] in
                self?.panelController?.hide()
            }
        } catch {
            print("Failed to initialize repository: \(error)")
        }
    }

    public func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "Emoji AI")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Emoji AI (⌃⌘Space)", action: #selector(togglePanel), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Emoji AI", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    public func setupHotKey() {
        let settings = SettingsManager.shared
        HotKeyManager.shared.register(combo: settings.hotKeyCombo) { [weak self] in
            Task { @MainActor in
                self?.handleHotKey()
            }
        }
    }

    @objc public func handleHotKey() {
        targetTracker.captureCurrentFrontmost()
        if let target = targetTracker.currentTarget {
            viewModel?.setTargetApp(target)
        }
        panelController?.toggle(target: targetTracker.currentTarget)
    }

    @objc public func togglePanel() {
        handleHotKey()
    }

    @objc public func openPreferences() {
        SettingsWindowController.shared.showPreferences()
    }

    @objc public func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
