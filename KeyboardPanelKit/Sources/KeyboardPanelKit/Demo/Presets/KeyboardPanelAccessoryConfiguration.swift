import SwiftUI

public struct KeyboardPanelAccessoryConfiguration: Sendable {
    public var placeholder: String
    public var sendButtonTitle: String
    public var colors: KeyboardPanelColors
    public var inputCornerRadius: CGFloat
    public var buttonSize: CGFloat
    public var spacing: CGFloat
    public var horizontalPadding: CGFloat
    public var verticalPadding: CGFloat
    
    public init(
        placeholder: String = "说点什么...",
        sendButtonTitle: String = "发送",
        colors: KeyboardPanelColors = .default,
        inputCornerRadius: CGFloat = 20,
        buttonSize: CGFloat = 32,
        spacing: CGFloat = 12,
        horizontalPadding: CGFloat = 12,
        verticalPadding: CGFloat = 8
    ) {
        self.placeholder = placeholder
        self.sendButtonTitle = sendButtonTitle
        self.colors = colors
        self.inputCornerRadius = inputCornerRadius
        self.buttonSize = buttonSize
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }
    
    public static let `default` = KeyboardPanelAccessoryConfiguration()
}
