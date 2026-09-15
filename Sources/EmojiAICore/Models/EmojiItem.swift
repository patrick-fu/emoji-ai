import Foundation

public struct EmojiItem: Codable, Identifiable, Sendable, Hashable {
    public var id: String { symbol }
    public let symbol: String
    public let category: String
    public let name: String
    public let aliases: [String]
    public let keywords: [String]
    public var customKeywords: [String]
    public let unicodeVersion: Double?

    enum CodingKeys: String, CodingKey {
        case symbol = "s"
        case category = "c"
        case name = "n"
        case aliases = "a"
        case keywords = "k"
        case unicodeVersion = "u"
        case customKeywords
    }

    public init(
        symbol: String,
        category: String,
        name: String,
        aliases: [String] = [],
        keywords: [String] = [],
        customKeywords: [String] = [],
        unicodeVersion: Double? = nil
    ) {
        self.symbol = symbol
        self.category = category
        self.name = name
        self.aliases = aliases
        self.keywords = keywords
        self.customKeywords = customKeywords
        self.unicodeVersion = unicodeVersion
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.category = try container.decode(String.self, forKey: .category)
        self.name = try container.decode(String.self, forKey: .name)
        self.aliases = (try? container.decode([String].self, forKey: .aliases)) ?? []
        self.keywords = (try? container.decode([String].self, forKey: .keywords)) ?? []
        self.customKeywords = (try? container.decode([String].self, forKey: .customKeywords)) ?? []
        self.unicodeVersion = try? container.decode(Double.self, forKey: .unicodeVersion)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(category, forKey: .category)
        try container.encode(name, forKey: .name)
        try container.encode(aliases, forKey: .aliases)
        try container.encode(keywords, forKey: .keywords)
        try container.encode(customKeywords, forKey: .customKeywords)
        try container.encodeIfPresent(unicodeVersion, forKey: .unicodeVersion)
    }
}

public struct EmojiCatalog: Codable, Sendable {
    public let version: Int
    public let emoji: [EmojiItem]
}
