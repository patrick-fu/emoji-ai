import Foundation
import SwiftUI
import AppKit

public struct EmojiPickerView: View {
    @ObservedObject public var viewModel: EmojiPickerViewModel
    @FocusState private var isSearchFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(minimum: 40, maximum: 58), spacing: 8), count: 8)

    public init(viewModel: EmojiPickerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Search Bar
            searchBarHeader

            Divider()
                .opacity(0.4)

            // 2. Main Emoji Grid Scroll View
            gridContent

            Divider()
                .opacity(0.4)

            // 3. Raycast-aligned Action Bar
            actionBarFooter
        }
        .frame(width: 680, height: 440)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .onAppear {
            isSearchFocused = true
            Task {
                await viewModel.loadInitialData()
            }
        }
    }

    // MARK: - Subviews

    private var searchBarHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)

            TextField("Search Emoji & Symbols...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .regular))
                .focused($isSearchFocused)
                .onChange(of: viewModel.searchText) { _, newValue in
                    Task {
                        await viewModel.search(query: newValue)
                    }
                }
                .onSubmit {
                    Task {
                        await viewModel.confirmSelection()
                    }
                }

            if viewModel.isLoadingAI {
                ProgressView()
                    .controlSize(.small)
            } else if !viewModel.searchText.isEmpty {
                Button(action: {
                    Task {
                        await viewModel.triggerAISearch()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Tab for AI")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var gridContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if !viewModel.aiResults.isEmpty {
                        sectionHeader(title: "AI Suggestions", count: viewModel.aiResults.count)
                        emojiGrid(items: viewModel.aiResults, startIndex: 0)
                    }

                    if viewModel.searchText.isEmpty && !viewModel.frequentlyUsed.isEmpty {
                        sectionHeader(title: "Frequently Used", count: viewModel.frequentlyUsed.count)
                        emojiGrid(items: viewModel.frequentlyUsed, startIndex: viewModel.aiResults.count)
                    }

                    sectionHeader(title: "All Emojis", count: viewModel.localResults.count)
                    let offset = viewModel.aiResults.count + (viewModel.searchText.isEmpty ? viewModel.frequentlyUsed.count : 0)
                    emojiGrid(items: viewModel.localResults, startIndex: offset)
                }
                .padding(16)
            }
            .onChange(of: viewModel.selectedIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.1)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
            Text("\(count)")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary.opacity(0.8))
        }
    }

    private func emojiGrid(items: [EmojiItem], startIndex: Int) -> some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.element.symbol) { index, item in
                let globalIndex = startIndex + index
                let isSelected = globalIndex == viewModel.selectedIndex

                Button(action: {
                    viewModel.selectedIndex = globalIndex
                    Task {
                        await viewModel.confirmSelection()
                    }
                }) {
                    Text(item.symbol)
                        .font(.system(size: 32))
                        .frame(width: 52, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .id(globalIndex)
            }
        }
    }

    private var actionBarFooter: some View {
        HStack(spacing: 12) {
            // Left Status
            HStack(spacing: 6) {
                Image(systemName: "character.bubble.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 11))
                Text(viewModel.statusText)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }

            Spacer()

            // Right Actions
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("Paste to \(viewModel.targetAppName)")
                        .font(.system(size: 12, weight: .medium))
                    Text("↵")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(4)
                }

                HStack(spacing: 4) {
                    Text("Actions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("⌘K")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.03))
    }
}

// Visual Effect View for macOS frosted glass effect
public struct VisualEffectView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public init(material: NSVisualEffectView.Material, blendingMode: NSVisualEffectView.BlendingMode) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
