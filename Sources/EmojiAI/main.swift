import Foundation
import EmojiAICore

@main
struct EmojiAIMain {
    static func main() async {
        print("Starting EmojiAI...")
        do {
            let repo = try EmojiRepository()
            try await repo.initialize()
            let total = try await repo.count()
            print("Loaded \(total) emojis successfully in SQLite database.")
        } catch {
            print("Failed to initialize repository: \(error)")
        }
    }
}
