import Foundation
import Carbon

public struct HotKeyCombo: Codable, Equatable, Sendable {
    public let keyCode: UInt32
    public let carbonModifiers: UInt32

    public init(keyCode: UInt32, carbonModifiers: UInt32) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }

    public static let defaultCombo = HotKeyCombo(
        keyCode: UInt32(kVK_Space),
        carbonModifiers: UInt32(cmdKey | controlKey)
    )

    public var displayString: String {
        var str = ""
        if carbonModifiers & UInt32(controlKey) != 0 { str += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { str += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { str += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { str += "⌘" }
        str += keyName(for: keyCode)
        return str
    }

    private func keyName(for code: UInt32) -> String {
        switch Int(code) {
        case kVK_Space: return "Space"
        case kVK_Return: return "↵"
        case kVK_Escape: return "Esc"
        case kVK_Tab: return "⇥"
        default:
            return "Key(\(code))"
        }
    }
}
