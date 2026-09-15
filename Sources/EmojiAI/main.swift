import Foundation
import EmojiAICore

@main
struct EmojiAIMain {
    static func main() async {
        print("Starting EmojiAI...")
        let repo = EmojiRepository()
        do {
            try await repo.loadBuiltinCatalog()
            let total = await repo.count()
            print("Loaded \(total) emojis successfully.")
        } catch {
            print("Failed to load catalog: \(error)")
        }
    }
}
