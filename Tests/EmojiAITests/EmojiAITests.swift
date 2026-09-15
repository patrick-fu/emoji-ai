import Testing
@testable import EmojiAICore

@Suite("EmojiAI Core Tests")
struct EmojiAITests {
    @Test("Test Built-in Catalog Loading and Search")
    func testCatalogLoadingAndSearch() async throws {
        let repo = EmojiRepository()
        try await repo.loadBuiltinCatalog()
        let total = await repo.count()
        #expect(total > 1000)

        let results = await repo.searchLocal(query: "smile")
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
