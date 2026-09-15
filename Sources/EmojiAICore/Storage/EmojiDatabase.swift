import Foundation
import SQLite3

public final class EmojiDatabase: @unchecked Sendable {
    private var db: OpaquePointer?
    private let lock = NSRecursiveLock()

    public enum DatabaseError: Error {
        case openFailed(String)
        case executeFailed(String)
        case prepareFailed(String)
    }

    public init(path: String) throws {
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(path, &handle, flags, nil) != SQLITE_OK {
            let msg = handle != nil ? String(cString: sqlite3_errmsg(handle)) : "Unknown error"
            throw DatabaseError.openFailed(msg)
        }
        self.db = handle
        try createSchema()
    }

    deinit {
        if let db = db {
            sqlite3_close_v2(db)
        }
    }

    private func createSchema() throws {
        let schema = """
        CREATE TABLE IF NOT EXISTS emojis (
            symbol TEXT PRIMARY KEY NOT NULL,
            category TEXT NOT NULL,
            name TEXT NOT NULL,
            aliases TEXT NOT NULL DEFAULT '[]',
            keywords TEXT NOT NULL DEFAULT '[]',
            customKeywords TEXT NOT NULL DEFAULT '[]',
            unicodeVersion REAL,
            frecencyScore REAL DEFAULT 0,
            lastUsedDate REAL DEFAULT 0
        );
        CREATE INDEX IF NOT EXISTS idx_emojis_category ON emojis(category);
        CREATE INDEX IF NOT EXISTS idx_emojis_frecency ON emojis(frecencyScore DESC);
        """
        try execute(sql: schema)
    }

    private func execute(sql: String) throws {
        lock.lock()
        defer { lock.unlock() }

        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            let msg = errMsg != nil ? String(cString: errMsg!) : "Unknown error"
            sqlite3_free(errMsg)
            throw DatabaseError.executeFailed(msg)
        }
    }

    public func seed(items: [EmojiItem]) throws {
        lock.lock()
        defer { lock.unlock() }

        try execute(sql: "BEGIN TRANSACTION;")
        let sql = """
        INSERT INTO emojis (symbol, category, name, aliases, keywords, customKeywords, unicodeVersion)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(symbol) DO UPDATE SET
            category = excluded.category,
            name = excluded.name,
            aliases = excluded.aliases,
            keywords = excluded.keywords,
            unicodeVersion = excluded.unicodeVersion;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(msg)
        }
        defer { sqlite3_finalize(stmt) }

        for item in items {
            sqlite3_reset(stmt)
            sqlite3_clear_bindings(stmt)

            sqlite3_bind_text(stmt, 1, (item.symbol as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (item.category as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (item.name as NSString).utf8String, -1, nil)

            let aliasesData = (try? JSONEncoder().encode(item.aliases)) ?? Data()
            let aliasesJson = String(data: aliasesData, encoding: .utf8) ?? "[]"
            sqlite3_bind_text(stmt, 4, (aliasesJson as NSString).utf8String, -1, nil)

            let keywordsData = (try? JSONEncoder().encode(item.keywords)) ?? Data()
            let keywordsJson = String(data: keywordsData, encoding: .utf8) ?? "[]"
            sqlite3_bind_text(stmt, 5, (keywordsJson as NSString).utf8String, -1, nil)

            let customData = (try? JSONEncoder().encode(item.customKeywords)) ?? Data()
            let customJson = String(data: customData, encoding: .utf8) ?? "[]"
            sqlite3_bind_text(stmt, 6, (customJson as NSString).utf8String, -1, nil)

            if let v = item.unicodeVersion {
                sqlite3_bind_double(stmt, 7, v)
            } else {
                sqlite3_bind_null(stmt, 7)
            }

            if sqlite3_step(stmt) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.executeFailed(msg)
            }
        }

        try execute(sql: "COMMIT;")
    }

    public func count() throws -> Int {
        lock.lock()
        defer { lock.unlock() }

        var stmt: OpaquePointer?
        let sql = "SELECT COUNT(*) FROM emojis;"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        return 0
    }

    public func search(query: String, limit: Int = 50) throws -> [EmojiItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleanQuery.isEmpty {
            return try getAll(limit: limit)
        }

        lock.lock()
        defer { lock.unlock() }

        let sql = """
        SELECT symbol, category, name, aliases, keywords, customKeywords, unicodeVersion
        FROM emojis
        WHERE symbol = ?
           OR LOWER(name) LIKE ?
           OR LOWER(aliases) LIKE ?
           OR LOWER(keywords) LIKE ?
           OR LOWER(customKeywords) LIKE ?
        ORDER BY frecencyScore DESC, symbol ASC
        LIMIT ?;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }

        let likePattern = "%\(cleanQuery)%"

        sqlite3_bind_text(stmt, 1, (cleanQuery as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (likePattern as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (likePattern as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, (likePattern as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 5, (likePattern as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 6, Int32(limit))

        var results: [EmojiItem] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let item = parseRow(stmt: stmt) {
                results.append(item)
            }
        }
        return results
    }

    public func getAll(limit: Int = 100) throws -> [EmojiItem] {
        lock.lock()
        defer { lock.unlock() }

        let sql = """
        SELECT symbol, category, name, aliases, keywords, customKeywords, unicodeVersion
        FROM emojis
        ORDER BY frecencyScore DESC, symbol ASC
        LIMIT ?;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(limit))

        var results: [EmojiItem] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let item = parseRow(stmt: stmt) {
                results.append(item)
            }
        }
        return results
    }

    public func addCustomKeyword(symbol: String, keyword: String) throws {
        let clean = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return }

        lock.lock()
        defer { lock.unlock() }

        // Fetch existing custom keywords
        var current: [String] = []
        let selectSql = "SELECT customKeywords FROM emojis WHERE symbol = ?;"
        var selectStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, selectSql, -1, &selectStmt, nil) == SQLITE_OK {
            sqlite3_bind_text(selectStmt, 1, (symbol as NSString).utf8String, -1, nil)
            if sqlite3_step(selectStmt) == SQLITE_ROW,
               let textPtr = sqlite3_column_text(selectStmt, 0) {
                let json = String(cString: textPtr)
                if let data = json.data(using: .utf8),
                   let list = try? JSONDecoder().decode([String].self, from: data) {
                    current = list
                }
            }
            sqlite3_finalize(selectStmt)
        }

        if !current.contains(clean) {
            current.append(clean)
        }

        let updatedData = (try? JSONEncoder().encode(current)) ?? Data()
        let updatedJson = String(data: updatedData, encoding: .utf8) ?? "[]"

        let updateSql = "UPDATE emojis SET customKeywords = ? WHERE symbol = ?;"
        var updateStmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, updateSql, -1, &updateStmt, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(updateStmt) }

        sqlite3_bind_text(updateStmt, 1, (updatedJson as NSString).utf8String, -1, nil)
        sqlite3_bind_text(updateStmt, 2, (symbol as NSString).utf8String, -1, nil)

        if sqlite3_step(updateStmt) != SQLITE_DONE {
            throw DatabaseError.executeFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    public func recordUsage(symbol: String) throws {
        lock.lock()
        defer { lock.unlock() }

        let sql = """
        UPDATE emojis
        SET frecencyScore = frecencyScore + 1.0,
            lastUsedDate = ?
        WHERE symbol = ?;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_double(stmt, 1, Date().timeIntervalSince1970)
        sqlite3_bind_text(stmt, 2, (symbol as NSString).utf8String, -1, nil)

        if sqlite3_step(stmt) != SQLITE_DONE {
            throw DatabaseError.executeFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    public func getFrequentlyUsed(limit: Int = 16) throws -> [EmojiItem] {
        lock.lock()
        defer { lock.unlock() }

        let sql = """
        SELECT symbol, category, name, aliases, keywords, customKeywords, unicodeVersion
        FROM emojis
        WHERE frecencyScore > 0
        ORDER BY frecencyScore DESC, lastUsedDate DESC
        LIMIT ?;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(limit))

        var results: [EmojiItem] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let item = parseRow(stmt: stmt) {
                results.append(item)
            }
        }
        return results
    }

    private func parseRow(stmt: OpaquePointer?) -> EmojiItem? {
        guard let stmt = stmt else { return nil }
        guard let symPtr = sqlite3_column_text(stmt, 0),
              let catPtr = sqlite3_column_text(stmt, 1),
              let namePtr = sqlite3_column_text(stmt, 2) else {
            return nil
        }

        let symbol = String(cString: symPtr)
        let category = String(cString: catPtr)
        let name = String(cString: namePtr)

        var aliases: [String] = []
        if let aPtr = sqlite3_column_text(stmt, 3) {
            let json = String(cString: aPtr)
            if let data = json.data(using: .utf8),
               let list = try? JSONDecoder().decode([String].self, from: data) {
                aliases = list
            }
        }

        var keywords: [String] = []
        if let kPtr = sqlite3_column_text(stmt, 4) {
            let json = String(cString: kPtr)
            if let data = json.data(using: .utf8),
               let list = try? JSONDecoder().decode([String].self, from: data) {
                keywords = list
            }
        }

        var customKeywords: [String] = []
        if let cPtr = sqlite3_column_text(stmt, 5) {
            let json = String(cString: cPtr)
            if let data = json.data(using: .utf8),
               let list = try? JSONDecoder().decode([String].self, from: data) {
                customKeywords = list
            }
        }

        let unicodeVersion: Double? = sqlite3_column_type(stmt, 6) != SQLITE_NULL ? sqlite3_column_double(stmt, 6) : nil

        return EmojiItem(
            symbol: symbol,
            category: category,
            name: name,
            aliases: aliases,
            keywords: keywords,
            customKeywords: customKeywords,
            unicodeVersion: unicodeVersion
        )
    }
}
