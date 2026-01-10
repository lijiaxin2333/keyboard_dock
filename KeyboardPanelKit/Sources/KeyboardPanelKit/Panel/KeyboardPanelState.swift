import Foundation

public enum KeyboardPanelState: Equatable, Sendable {
    case keyboard
    case panel(String)
    case none
    
    public var isKeyboard: Bool {
        if case .keyboard = self { return true }
        return false
    }
    
    public var isPanel: Bool {
        if case .panel = self { return true }
        return false
    }
    
    public var currentPanelId: String? {
        if case .panel(let id) = self { return id }
        return nil
    }
}
