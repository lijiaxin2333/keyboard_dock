import SwiftUI

public struct KeyboardPanelContext {
    public let panelState: KeyboardPanelState
    public let keyboardHeight: CGFloat
    public let panelDisplayHeight: CGFloat
    public let isTransitioning: Bool
    public let bottomSafeAreaHeight: CGFloat
    
    public let showPanel: (String) -> Void
    public let showKeyboard: () -> Void
    public let requestShowKeyboard: () -> Void
    public let dismiss: () -> Void
    
    public var insertText: ((String) -> Void)?
    public var clearContent: (() -> Void)?
    
    public var userInfo: [String: Any]
    
    public var currentPanelId: String? {
        panelState.currentPanelId
    }
    
    public var isKeyboardVisible: Bool {
        panelState.isKeyboard
    }
    
    public var isPanelVisible: Bool {
        panelState.isPanel
    }
    
    public init(
        panelState: KeyboardPanelState,
        keyboardHeight: CGFloat,
        panelDisplayHeight: CGFloat,
        isTransitioning: Bool,
        bottomSafeAreaHeight: CGFloat,
        showPanel: @escaping (String) -> Void,
        showKeyboard: @escaping () -> Void,
        requestShowKeyboard: @escaping () -> Void,
        dismiss: @escaping () -> Void,
        insertText: ((String) -> Void)? = nil,
        clearContent: (() -> Void)? = nil,
        userInfo: [String: Any] = [:]
    ) {
        self.panelState = panelState
        self.keyboardHeight = keyboardHeight
        self.panelDisplayHeight = panelDisplayHeight
        self.isTransitioning = isTransitioning
        self.bottomSafeAreaHeight = bottomSafeAreaHeight
        self.showPanel = showPanel
        self.showKeyboard = showKeyboard
        self.requestShowKeyboard = requestShowKeyboard
        self.dismiss = dismiss
        self.insertText = insertText
        self.clearContent = clearContent
        self.userInfo = userInfo
    }
}

private struct KeyboardPanelContextKey: EnvironmentKey {
    static var defaultValue: KeyboardPanelContext?
}

extension EnvironmentValues {
    public var keyboardPanelContext: KeyboardPanelContext? {
        get { self[KeyboardPanelContextKey.self] }
        set { self[KeyboardPanelContextKey.self] = newValue }
    }
}
