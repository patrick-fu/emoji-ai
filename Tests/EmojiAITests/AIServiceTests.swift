import Testing
import Foundation
@testable import EmojiAICore

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

@Suite("AIService Tests", .serialized)
struct AIServiceTests {
    @Test("Test OpenAI Chat Completions Request and Response Parsing")
    func testAIServiceRequestAndParsing() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.absoluteString == "https://api.openai.com/v1/chat/completions")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test-key")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let responseJson = """
            {
              "id": "chatcmpl-123",
              "object": "chat.completion",
              "created": 1677652288,
              "model": "gpt-4o-mini",
              "choices": [{
                "index": 0,
                "message": {
                  "role": "assistant",
                  "content": "🫠, 🫨, 🤯, 🥵"
                },
                "finish_reason": "stop"
              }]
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseJson.data(using: .utf8)!)
        }

        let aiConfig = AIServiceConfig(
            baseURL: "https://api.openai.com/v1",
            apiKey: "sk-test-key",
            model: "gpt-4o-mini"
        )
        let service = AIService(config: aiConfig, session: session)
        let emojis = try await service.searchRelevantEmojis(query: "exhausted after overtime")

        #expect(emojis == ["🫠", "🫨", "🤯", "🥵"])
    }

    @Test("Test AIService Parsing with Mixed Output")
    func testAIServiceMixedOutput() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        MockURLProtocol.requestHandler = { request in
            let responseJson = """
            {
              "choices": [{
                "message": {
                  "content": "Here are your emojis: 🚀, 💻, ✨."
                }
              }]
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJson.data(using: .utf8)!)
        }

        let service = AIService(config: AIServiceConfig(apiKey: "key"), session: session)
        let emojis = try await service.searchRelevantEmojis(query: "code deploy")
        #expect(emojis.contains("🚀"))
        #expect(emojis.contains("💻"))
        #expect(emojis.contains("✨"))
    }
}
