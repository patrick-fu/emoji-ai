# Emoji AI (emoji-ai)

A native, high-performance macOS emoji picker with AI semantic search and BYOK (Bring Your Own Key) support.

Inspired by Raycast's built-in "Search Emoji & Symbols" feature, **Emoji AI** provides an instant, keyboard-driven floating picker that lets you search emojis through both traditional keyword matching and natural-language AI queries.

---

## 🌟 Features

- **Ghost Panel UI**: Built with AppKit `NSPanel` (`.nonactivatingPanel`), allowing search and keyboard navigation without stealing focus from active applications (Chrome, VS Code, Slack, Terminal).
- **Two-Tier Search Engine**:
  - **L1 Instant Local Search (< 1ms)**: Built-in catalog of 2,400+ Unicode emojis with comprehensive names, categories, aliases, and keywords.
  - **L2 AI Semantic Search**: Natural-language semantic queries (e.g., `"feeling exhausted after overtime"`, `"victory celebration"`, `"spicy food"`) powered by LLMs.
- **BYOK (Bring Your Own Key)**: Full support for OpenAI-compatible endpoints (`baseURL`, `apiKey`, `model`). Connect OpenAI, DeepSeek, Moonshot/Kimi, OpenRouter, or local Ollama instances.
- **Adaptive Learning Cache**: Automatically associates user-selected AI results with the original query as `customKeywords`, ensuring future searches for the same term resolve locally with zero latency and zero API cost.
- **Cursor-Aware Auto Placement**: Automatically positions the floating window next to the text caret via macOS Accessibility APIs, with smooth fallback to screen center.
- **Instant Insertion**: Directly injects chosen emojis into the target application or copies them to clipboard.

---

## 🏗 Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                    Global Shortcut                          │
│               (Cmd + Ctrl + Space / Custom)                 │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│             Ghost Panel (NSPanel .nonactivatingPanel)        │
│             Keeps active window focus intact                │
└──────────────────────────────┬──────────────────────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
┌────────────────────────┐            ┌────────────────────────┐
│  Tier 1: Local Engine  │            │   Tier 2: AI Engine    │
│ - Unicode 17 Catalog   │ (No match  │ - Custom baseURL / Key │
│ - In-memory Trie / FTS │   or Tab)  │ - OpenAI-compatible API│
│ - Custom keyword cache │───────────>│ - Structured output    │
└────────────────────────┘            └────────────────────────┘
            │                                     │
            └──────────────────┬──────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                Emoji Selection & Injection                  │
│             Accessibility API / CGEventPost                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠 Tech Stack

- **Language**: Swift 6.2+
- **Frameworks**: AppKit (Windowing & HotKey), SwiftUI (UI & Views), Foundation
- **Build System**: Swift Package Manager (SPM)
- **Minimum macOS Version**: macOS 14.0 (Sonoma) or higher

---

## 🚀 Getting Started

### Prerequisites

- macOS 14.0+
- Xcode 16+ or Command Line Tools (`swift --version` >= 6.0)

### Build & Run

```bash
# Clone the repository
git clone https://github.com/patrick-fu/emoji-ai.git
cd emoji-ai

# Run tests
swift test

# Build and run the CLI runner
swift run EmojiAI
```

---

## ⚙️ Configuration (BYOK)

`AIServiceConfig` supports any standard OpenAI-compatible completions API:

```json
{
  "baseURL": "https://api.openai.com/v1",
  "apiKey": "sk-...",
  "model": "gpt-4o-mini",
  "temperature": 0.3
}
```

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
