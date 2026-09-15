import Testing
import Foundation
@testable import EmojiAICore

@Suite("EmojiPickerViewModel Tests")
struct EmojiPickerViewModelTests {
    @Test("Test ViewModel search and selection navigation")
    @MainActor
    func testSearchAndSelection() async throws {
        let memDb = try EmojiDatabase(path: ":memory:")
        let repo = try EmojiRepository(database: memDb)
        try await repo.initialize()

        let vm = EmojiPickerViewModel(repository: repo)
        await vm.loadInitialData()

        #expect(!vm.localResults.isEmpty)
        #expect(vm.selectedIndex == 0)

        // Perform search
        await vm.search(query: "smile")
        #expect(!vm.localResults.isEmpty)
        #expect(vm.selectedIndex == 0)

        // Navigation
        vm.moveSelection(dx: 1, dy: 0, columns: 8)
        #expect(vm.selectedIndex == 1)

        vm.moveSelection(dx: 0, dy: 1, columns: 8)
        #expect(vm.selectedIndex == 9)
    }

    @Test("Test ViewModel confirmation and self-learning callback")
    @MainActor
    func testConfirmationAndSelfLearning() async throws {
        let memDb = try EmojiDatabase(path: ":memory:")
        let repo = try EmojiRepository(database: memDb)
        try await repo.initialize()

        let vm = EmojiPickerViewModel(repository: repo)
        await vm.search(query: "funny clown")

        var selectedEmoji: String?
        vm.onSelectEmoji = { emoji in
            selectedEmoji = emoji
        }

        // Set clown face as custom result
        vm.localResults = [
            EmojiItem(symbol: "🤡", category: "smileys_people", name: "clown face")
        ]
        vm.selectedIndex = 0

        await vm.confirmSelection()

        #expect(selectedEmoji == "🤡")

        // Verify that custom keyword "funny clown" was learned into repo
        let learned = try await repo.searchLocal(query: "funny clown")
        #expect(learned.contains(where: { $0.symbol == "🤡" }))
    }
}
