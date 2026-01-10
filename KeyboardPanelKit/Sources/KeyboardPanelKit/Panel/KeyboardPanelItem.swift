import SwiftUI

public struct KeyboardPanelItem: Identifiable, Equatable {
    public let id: String
    public let icon: Image
    public let selectedIcon: Image?
    public let title: String?
    
    public init(
        id: String,
        icon: Image,
        selectedIcon: Image? = nil,
        title: String? = nil
    ) {
        self.id = id
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.title = title
    }
    
    public static func == (lhs: KeyboardPanelItem, rhs: KeyboardPanelItem) -> Bool {
        lhs.id == rhs.id
    }
    
    public static let at = KeyboardPanelItem(
        id: "at",
        icon: Image(systemName: "at")
    )
    
    public static let emoji = KeyboardPanelItem(
        id: "emoji",
        icon: Image(systemName: "face.smiling"),
        selectedIcon: Image(systemName: "keyboard")
    )
    
    public static let photo = KeyboardPanelItem(
        id: "photo",
        icon: Image(systemName: "photo")
    )
    
    public static let voice = KeyboardPanelItem(
        id: "voice",
        icon: Image(systemName: "mic")
    )
    
    public static let more = KeyboardPanelItem(
        id: "more",
        icon: Image(systemName: "plus.circle")
    )
}

public enum KeyboardPanelState: Equatable {
    case keyboard
    case panel(KeyboardPanelItem)
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
        if case .panel(let item) = self { return item.id }
        return nil
    }
}
