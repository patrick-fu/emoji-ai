import Testing
import Foundation
@testable import EmojiAICore

@Suite("EmojiDatabase Tests")
struct EmojiDatabaseTests {
    @Test("Test in-memory SQLite database seeding, search, and customKeywords self-learning")
    func testDatabaseLifecycle() async throws {
        let db = try EmojiDatabase(path: ":memory:")

        let clown = EmojiItem(
            symbol: "🤡",
            category: "smileys_people",
            name: "clown face",
            aliases: ["clown"],
            keywords: ["face", "circus"]
        )
        let chestnut = EmojiItem(
            symbol: "🌰",
            category: "food_drink",
            name: "chestnut",
            aliases: ["chestnut"],
            keywords: ["nut", "food"]
        )

        try db.seed(items: [clown, chestnut])
        #expect(try db.count() == 2)

        // 1. Initial local search
        let initialSearch = try db.search(query: "circus")
        #expect(initialSearch.count == 1)
        #expect(initialSearch.first?.symbol == "🤡")

        // 2. Query before self-learning
        let beforeLearning = try db.search(query: "小丑")
        #expect(beforeLearning.isEmpty)

        // 3. Self-learning: add custom keyword
        try db.addCustomKeyword(symbol: "🤡", keyword: "小丑")

        // 4. Query after self-learning
        let afterLearning = try db.search(query: "小丑")
        #expect(afterLearning.count == 1)
        #expect(afterLearning.first?.symbol == "🤡")
        #expect(afterLearning.first?.customKeywords.contains("小丑") == true)

        // 5. Usage recording and frecency
        try db.recordUsage(symbol: "🌰")
        let recent = try db.getFrequentlyUsed(limit: 5)
        #expect(!recent.isEmpty)
        #expect(recent.first?.symbol == "🌰")
    }
}
