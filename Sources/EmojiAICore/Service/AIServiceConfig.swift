import Foundation

public struct AIServiceConfig: Sendable, Codable {
    public var baseURL: String
    public var apiKey: String
    public var model: String
    public var temperature: Double

    public init(
        baseURL: String = "https://api.openai.com/v1",
        apiKey: String = "",
        model: String = "gpt-4o-mini",
        temperature: Double = 0.3
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.temperature = temperature
    }

    public static let defaultPromptTemplate = """
    You help find the most relevant emojis for a specific query.
    Respond with a message of comma-separated list of up to 10 emojis that represent query the best.

    Some rules:
    - ONLY respond with the list of emojis
    - NEVER include any generic emojis, e.g. 👨 for a male person
    - ALWAYS be creative to match the user's query as best as possible

    Query:
    {query}
    """
}
