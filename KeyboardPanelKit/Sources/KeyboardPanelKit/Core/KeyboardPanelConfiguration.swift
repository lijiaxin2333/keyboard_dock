import Foundation

public struct KeyboardPanelConfiguration: Sendable {
    public var animationDuration: TimeInterval
    public var defaultKeyboardHeight: CGFloat
    
    public init(
        animationDuration: TimeInterval = 0.25,
        defaultKeyboardHeight: CGFloat = 336
    ) {
        self.animationDuration = animationDuration
        self.defaultKeyboardHeight = defaultKeyboardHeight
    }
    
    public static let `default` = KeyboardPanelConfiguration()
}
