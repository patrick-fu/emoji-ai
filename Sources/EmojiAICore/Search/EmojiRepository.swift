import Foundation

public actor EmojiRepository {
    private let database: EmojiDatabase
    private var isInitialized = false

    public init(database: EmojiDatabase? = nil) throws {
        if let db = database {
            self.database = db
        } else {
            // Default persistent path in Application Support
            let fileManager = FileManager.default
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent("EmojiAI", isDirectory: true)
            if !fileManager.fileExists(atPath: dir.path) {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            let dbPath = dir.appendingPathComponent("emojis.sqlite").path
            self.database = try EmojiDatabase(path: dbPath)
        }
    }

    public func initialize() throws {
        guard !isInitialized else { return }
        let count = try database.count()
        if count == 0 {
            try loadBuiltinCatalog()
        }
        self.isInitialized = true
    }

    public func loadBuiltinCatalog() throws {
        guard let url = Bundle.module.url(forResource: "emoji", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        let catalog = try JSONDecoder().decode(EmojiCatalog.self, from: data)
        try database.seed(items: catalog.emoji)
    }

    public func count() throws -> Int {
        return try database.count()
    }

    public func searchLocal(query: String, limit: Int = 30) throws -> [EmojiItem] {
        return try database.search(query: query, limit: limit)
    }

    public func getFrequentlyUsed(limit: Int = 16) throws -> [EmojiItem] {
        return try database.getFrequentlyUsed(limit: limit)
    }

    public func recordUsage(symbol: String) throws {
        try database.recordUsage(symbol: symbol)
    }

    public func addCustomKeyword(symbol: String, keyword: String) throws {
        try database.addCustomKeyword(symbol: symbol, keyword: keyword)
    }
}
