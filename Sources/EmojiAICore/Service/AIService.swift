import Foundation

public final class AIService: Sendable {
    public let config: AIServiceConfig
    private let session: URLSession

    public enum AIError: LocalizedError, Sendable {
        case invalidURL(String)
        case emptyAPIKey
        case httpError(statusCode: Int, message: String)
        case emptyResponse
        case decodingError(String)

        public var errorDescription: String? {
            switch self {
            case .invalidURL(let url): return "Invalid API URL: \(url)"
            case .emptyAPIKey: return "API key is empty"
            case .httpError(let code, let msg): return "HTTP Error \(code): \(msg)"
            case .emptyResponse: return "Received empty response from AI service"
            case .decodingError(let msg): return "Failed to decode response: \(msg)"
            }
        }
    }

    public init(config: AIServiceConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    public func searchRelevantEmojis(query: String) async throws -> [String] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return [] }

        var base = config.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while base.hasSuffix("/") {
            base.removeLast()
        }
        let endpointString = base.hasSuffix("/chat/completions") ? base : "\(base)/chat/completions"
        guard let url = URL(string: endpointString) else {
            throw AIError.invalidURL(endpointString)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !config.apiKey.isEmpty {
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 15.0

        

        let requestPayload: [String: Any] = [
            "model": config.model,
            "temperature": config.temperature,
            "messages": [
                [
                    "role": "system",
                    "content": "You help find the most relevant emojis for a specific query.\nRespond with a message of comma-separated list of up to 10 emojis that represent query the best.\n\nSome rules:\n- ONLY respond with the list of emojis\n- NEVER include any generic emojis, e.g. 👨 for a male person\n- ALWAYS be creative to match the user's query as best as possible\n"
                ],
                [
                    "role": "user",
                    "content": "Query:\n\(cleanQuery)"
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestPayload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.emptyResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw AIError.httpError(statusCode: httpResponse.statusCode, message: errorText)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.emptyResponse
        }

        return extractEmojis(from: content)
    }

    private func extractEmojis(from text: String) -> [String] {
        var results: [String] = []

        // Split by commas, semicolons, whitespace, or enumerate characters
        // First try comma-separated splitting
        let parts = text.components(separatedBy: CharacterSet(charactersIn: ",;\n"))
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            // Extract emoji characters from the token
            for char in trimmed {
                if char.isEmojiCharacter && !results.contains(String(char)) {
                    results.append(String(char))
                }
            }
        }

        // Fallback if no emojis found via delimiter split
        if results.isEmpty {
            for char in text {
                if char.isEmojiCharacter && !results.contains(String(char)) {
                    results.append(String(char))
                }
            }
        }

        return Array(results.prefix(10))
    }
}

private extension Character {
    var isEmojiCharacter: Bool {
        for scalar in unicodeScalars {
            if scalar.properties.isEmoji && (scalar.properties.isEmojiPresentation || scalar.value > 0x2380) {
                return true
            }
        }
        return false
    }
}
