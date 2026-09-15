import Testing
@testable import EmojiAICore

@Suite("EmojiAI Core Tests")
struct EmojiAITests {
    @Test("Test Built-in Catalog Loading and Search via SQLite")
    func testCatalogLoadingAndSearch() async throws {
        let memDb = try EmojiDatabase(path: ":memory:")
        let repo = try EmojiRepository(database: memDb)
        try await repo.initialize()
        let total = try await repo.count()
        #expect(total > 1000)

        let results = try await repo.searchLocal(query: "smile")
        #expect(!results.isEmpty)
        #expect(results.first?.symbol != nil)
    }

    @Test("Test AIServiceConfig default values")
    func testAIServiceConfig() throws {
        let config = AIServiceConfig()
        #expect(config.baseURL == "https://api.openai.com/v1")
        #expect(config.model == "gpt-4o-mini")
        #expect(config.temperature == 0.3)
    }
}
