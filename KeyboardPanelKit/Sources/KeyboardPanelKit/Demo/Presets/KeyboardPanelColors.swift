import SwiftUI

public struct KeyboardPanelColors: Sendable {
    public var accessoryBackground: Color
    public var panelBackground: Color
    public var inputBackground: Color
    public var inputText: Color
    public var inputPlaceholder: Color
    public var buttonTint: Color
    public var sendButtonBackground: Color
    public var sendButtonForeground: Color
    public var divider: Color
    
    public init(
        accessoryBackground: Color = Color(uiColor: .systemGray6),
        panelBackground: Color = Color(uiColor: .systemGray6),
        inputBackground: Color = Color(uiColor: .systemGray5),
        inputText: Color = .primary,
        inputPlaceholder: Color = Color(uiColor: .placeholderText),
        buttonTint: Color = .primary,
        sendButtonBackground: Color = Color(red: 0.55, green: 0.2, blue: 0.2),
        sendButtonForeground: Color = .white,
        divider: Color = Color(uiColor: .separator)
    ) {
        self.accessoryBackground = accessoryBackground
        self.panelBackground = panelBackground
        self.inputBackground = inputBackground
        self.inputText = inputText
        self.inputPlaceholder = inputPlaceholder
        self.buttonTint = buttonTint
        self.sendButtonBackground = sendButtonBackground
        self.sendButtonForeground = sendButtonForeground
        self.divider = divider
    }
    
    public static let `default` = KeyboardPanelColors()
    
    public static let dark = KeyboardPanelColors(
        accessoryBackground: Color(white: 0.15),
        panelBackground: Color(white: 0.15),
        inputBackground: Color(white: 0.25),
        inputText: .white,
        inputPlaceholder: Color(white: 0.5),
        buttonTint: .white,
        sendButtonBackground: Color(red: 0.55, green: 0.2, blue: 0.2),
        sendButtonForeground: .white,
        divider: Color(white: 0.3)
    )
}
