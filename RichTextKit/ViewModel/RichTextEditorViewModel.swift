import Foundation
import Combine

@MainActor
public final class RichTextEditorViewModel: ObservableObject {
    
    @Published public private(set) var content: RichTextContent = RichTextContent()
    @Published public private(set) var activeTrigger: RichTextTrigger?
    @Published public private(set) var searchKeyword: String = ""
    @Published public internal(set) var pendingContent: RichTextContent?
    @Published public internal(set) var pendingInsertTokenCommand: InsertTokenCommand?
    @Published public var isEditable: Bool = true
    
    /// UI 配置
    public var editorConfig: RichTextEditorStyle {
        didSet {
            onTokenTap = editorConfig.onTokenTap
        }
    }

    /// 点击富文本 token（例如 @提及、#话题#）的回调。
    /// - Note: 只有在 token 的 attributed string 上设置了点击高亮（YYTextHighlight）时才会触发。
    public var onTokenTap: ((RichTextItem) -> Void)?

    /// 统一处理 token 点击：若对应 type 配置了 `RichTextTokenConfig.onTap`，则优先走该回调；
    /// 否则回退到 `onTokenTap`（全局回调）。
    public func handleTokenTap(item: RichTextItem) {
        if let config = configuration.tokenConfig(for: item.type),
           let onTap = config.onTap {
            onTap(item)
            return
        }
        onTokenTap?(item)
    }
    
    private var triggerLocation: Int = 0
    
    private let configuration: RichTextConfiguration
    
    public init(
        configuration: RichTextConfiguration,
        editorConfig: RichTextEditorStyle = .default
    ) {
        self.configuration = configuration
        self.editorConfig = editorConfig
        self.onTokenTap = editorConfig.onTokenTap
    }
    
    public convenience init(
        editorConfig: RichTextEditorStyle = .default
    ) {
        self.init(configuration: RichTextConfiguration(), editorConfig: editorConfig)
    }
    
    public func getTriggerLocation() -> Int {
        triggerLocation
    }
    
    public func getConfiguration() -> RichTextConfiguration {
        configuration
    }
    
    public func setContent(_ content: RichTextContent) {
        pendingContent = content
    }
    
    public func clearContent() {
        let empty = RichTextContent()
        pendingContent = empty
    }
    
    public func clearPendingContent() {
        pendingContent = nil
    }

    public func insertToken(item: any SuggestionItem, trigger: RichTextTrigger) {
        pendingInsertTokenCommand = InsertTokenCommand(mode: .replaceTrigger, item: item, trigger: trigger)
    }

    public func insertTokenAtCursor(item: any SuggestionItem, trigger: RichTextTrigger) {
        pendingInsertTokenCommand = InsertTokenCommand(mode: .atCursor, item: item, trigger: trigger)
    }

    public func clearPendingInsertTokenCommand() {
        pendingInsertTokenCommand = nil
    }
    
    public func shouldChangeText(in range: NSRange, replacementText text: String, currentText: NSAttributedString) -> Bool {
        if let trigger = configuration.trigger(for: text) {
            triggerLocation = range.location
            activeTrigger = trigger
            searchKeyword = ""
            return true
        }
        
        if activeTrigger != nil {
            if text == " " || text == "\n" {
                dismissSuggestionPanel()
            } else if text.isEmpty && range.location <= triggerLocation {
                dismissSuggestionPanel()
            } else {
                updateSearchKeyword(range: range, replacementText: text, currentText: currentText)
            }
        }
        
        return true
    }
    
    public func textDidChange(_ attributedText: NSAttributedString) {
        parseContent(from: attributedText)
    }
    
    public func dismissSuggestionPanel() {
        let previousTrigger = activeTrigger
        activeTrigger = nil
        searchKeyword = ""
    }
    
    public func buildRichTextItem(from suggestion: any SuggestionItem, trigger: RichTextTrigger) -> RichTextItem {
        if let config = configuration.tokenConfig(for: trigger.tokenType) {
            return config.dataBuilder(suggestion)
        }
        let text = trigger.formatTokenText(item: suggestion)
        return RichTextItem(type: trigger.tokenType, displayText: text, data: suggestion.id)
    }
    
    private func updateSearchKeyword(range: NSRange, replacementText text: String, currentText: NSAttributedString) {
        let origin = currentText.string as NSString
        let mutable = NSMutableString(string: origin)
        mutable.replaceCharacters(in: range, with: text)
        
        let start = min(triggerLocation + 1, mutable.length)
        let cursor = min(range.location + (text as NSString).length, mutable.length)
        if cursor <= start {
            searchKeyword = ""
        } else {
            let sub = mutable.substring(with: NSRange(location: start, length: cursor - start))
            if let stop = sub.firstIndex(where: { $0 == " " || $0 == "\n" || $0 == "\t" }) {
                searchKeyword = String(sub[..<stop])
            } else {
                searchKeyword = sub
            }
        }
    }
    
    private func parseContent(from attributedText: NSAttributedString) {
        var items: [RichTextItem] = []
        var currentText = ""
        
        attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length)) { attrs, range, _ in
            if let itemType = attrs[.richTextItemType] as? String,
               let itemId = attrs[.richTextItemId] as? String {
                if !currentText.isEmpty {
                    items.append(.text(currentText))
                    currentText = ""
                }
                let rangeText = (attributedText.string as NSString).substring(with: range)
                let storedText = attrs[.richTextItemDisplayText] as? String
                let displayText = rangeText == "\u{FFFC}" ? (storedText ?? "") : rangeText
                let payload = attrs[.richTextItemPayload] as? String
                items.append(RichTextItem(type: itemType, displayText: displayText, data: itemId, payload: payload))
            } else {
                let text = (attributedText.string as NSString).substring(with: range)
                currentText += text
            }
        }
        
        if !currentText.isEmpty {
            items.append(.text(currentText))
        }
        
        content = RichTextContent(items: items)
    }
    
}

public struct InsertTokenCommand: Sendable {
    public enum Mode: Sendable {
        case replaceTrigger
        case atCursor
    }

    public let mode: Mode
    public let item: any SuggestionItem
    public let trigger: RichTextTrigger

    public init(mode: Mode, item: any SuggestionItem, trigger: RichTextTrigger) {
        self.mode = mode
        self.item = item
        self.trigger = trigger
    }
}

public extension NSAttributedString.Key {
    static let richTextItemType = NSAttributedString.Key("richTextItemType")
    static let richTextItemId = NSAttributedString.Key("richTextItemId")
    static let richTextItemDisplayText = NSAttributedString.Key("richTextItemDisplayText")
    static let richTextItemPayload = NSAttributedString.Key("richTextItemPayload")
}
