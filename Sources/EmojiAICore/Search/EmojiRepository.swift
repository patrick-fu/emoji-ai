import Foundation

public actor EmojiRepository {
    private var emojis: [EmojiItem] = []
    private var isLoaded = false

    public init() {}

    public func loadBuiltinCatalog() throws {
        guard !isLoaded else { return }
        guard let url = Bundle.module.url(forResource: "emoji", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        let catalog = try JSONDecoder().decode(EmojiCatalog.self, from: data)
        self.emojis = catalog.emoji
        self.isLoaded = true
    }

    public func count() -> Int {
        return emojis.count
    }

    public func searchLocal(query: String, limit: Int = 20) -> [EmojiItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanQuery.isEmpty else {
            return Array(emojis.prefix(limit))
        }

        return emojis.filter { item in
            if item.symbol == cleanQuery { return true }
            if item.name.lowercased().contains(cleanQuery) { return true }
            if item.aliases.contains(where: { $0.lowercased().contains(cleanQuery) }) { return true }
            if item.keywords.contains(where: { $0.lowercased().contains(cleanQuery) }) { return true }
            if item.customKeywords.contains(where: { $0.lowercased().contains(cleanQuery) }) { return true }
            return false
        }.prefix(limit).map { $0 }
    }
}
