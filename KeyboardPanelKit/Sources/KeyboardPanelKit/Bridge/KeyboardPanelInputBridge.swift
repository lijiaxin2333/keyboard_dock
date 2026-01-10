import Foundation

public protocol KeyboardPanelInputBridge: AnyObject {
    var plainText: String { get }
    var isEmpty: Bool { get }
    
    func insertText(_ text: String)
    func clearContent()
    
    var onContentChanged: ((String) -> Void)? { get set }
}

public protocol KeyboardPanelTokenInputBridge: KeyboardPanelInputBridge {
    associatedtype TokenItem
    associatedtype TriggerType
    
    func insertToken(_ item: TokenItem, trigger: TriggerType)
    
    var activeTrigger: TriggerType? { get }
    var searchKeyword: String { get }
    var onTriggerChanged: ((TriggerType?, String) -> Void)? { get set }
}

public final class SimpleTextInputBridge: KeyboardPanelInputBridge {
    private var _text: String
    public var onContentChanged: ((String) -> Void)?
    
    public var plainText: String { _text }
    public var isEmpty: Bool { _text.isEmpty }
    
    public init(text: String = "") {
        self._text = text
    }
    
    public func insertText(_ text: String) {
        _text += text
        onContentChanged?(_text)
    }
    
    public func clearContent() {
        _text = ""
        onContentChanged?(_text)
    }
    
    public func setText(_ text: String) {
        _text = text
        onContentChanged?(_text)
    }
}
