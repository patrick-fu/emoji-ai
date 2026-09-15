import Foundation
import SwiftUI

@MainActor
public final class EmojiPickerViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var localResults: [EmojiItem] = []
    @Published public var aiResults: [EmojiItem] = []
    @Published public var frequentlyUsed: [EmojiItem] = []
    @Published public var selectedCategory: String? = nil
    @Published public var selectedIndex: Int = 0
    @Published public var isLoadingAI: Bool = false
    @Published public var targetAppName: String = "Active App"
    @Published public var statusText: String = "Search Emoji & Symbols"

    public var onSelectEmoji: ((String) -> Void)?
    public var onClose: (() -> Void)?

    private let repository: EmojiRepository
    private var aiService: AIService?

    public init(repository: EmojiRepository, aiService: AIService? = nil) {
        self.repository = repository
        self.aiService = aiService
    }

    public func configureAIService(_ service: AIService?) {
        self.aiService = service
    }

    public func setTargetApp(_ app: NSRunningApplication?) {
        self.targetAppName = app?.localizedName ?? "Active App"
    }

    public func loadInitialData() async {
        do {
            try await repository.initialize()
            self.frequentlyUsed = try await repository.getFrequentlyUsed(limit: 16)
            self.localResults = try await repository.searchLocal(query: "", limit: 120)
            updateStatus()
        } catch {
            print("Failed to load initial data: \(error)")
        }
    }

    public func search(query: String) async {
        self.searchText = query
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            self.localResults = try await repository.searchLocal(query: clean, limit: 120)
            self.selectedIndex = 0
            updateStatus()

            // If local results are empty and query is present, trigger AI
            if localResults.isEmpty && !clean.isEmpty && aiService != nil && !isLoadingAI {
                await triggerAISearch()
            }
        } catch {
            print("Search error: \(error)")
        }
    }

    public func triggerAISearch() async {
        let clean = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let aiService = aiService, !clean.isEmpty, !isLoadingAI else { return }

        self.isLoadingAI = true
        defer { self.isLoadingAI = false }

        do {
            let symbols = try await aiService.searchRelevantEmojis(query: clean)
            var items: [EmojiItem] = []
            for sym in symbols {
                if let matched = try await repository.searchLocal(query: sym, limit: 1).first {
                    items.append(matched)
                } else {
                    items.append(EmojiItem(symbol: sym, category: "ai_result", name: "AI Suggestion"))
                }
            }
            self.aiResults = items
            if !items.isEmpty {
                self.selectedIndex = 0
            }
            updateStatus()
        } catch {
            print("AI search error: \(error)")
        }
    }

    public var displayedItems: [EmojiItem] {
        if !aiResults.isEmpty {
            return aiResults + localResults
        }
        return localResults
    }

    public var currentSelectedItem: EmojiItem? {
        let items = displayedItems
        guard selectedIndex >= 0 && selectedIndex < items.count else { return nil }
        return items[selectedIndex]
    }

    public func moveSelection(dx: Int, dy: Int, columns: Int = 8) {
        let items = displayedItems
        guard !items.isEmpty else { return }

        let count = items.count
        var newIndex = selectedIndex + dx + (dy * columns)
        if newIndex < 0 { newIndex = 0 }
        if newIndex >= count { newIndex = count - 1 }
        self.selectedIndex = newIndex
        updateStatus()
    }

    public func confirmSelection() async {
        guard let item = currentSelectedItem else { return }

        try? await repository.recordUsage(symbol: item.symbol)

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            try? await repository.addCustomKeyword(symbol: item.symbol, keyword: query)
        }

        onSelectEmoji?(item.symbol)
    }

    private func updateStatus() {
        if let item = currentSelectedItem {
            statusText = "Search Emoji & Symbols - \(item.name.capitalized)"
        } else {
            statusText = "Search Emoji & Symbols"
        }
    }
}
