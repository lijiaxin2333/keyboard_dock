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
    
    public func icon(for state: KeyboardPanelState) -> Image {
        if state.currentPanelId == id, let selectedIcon = selectedIcon {
            return selectedIcon
        }
        return icon
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
