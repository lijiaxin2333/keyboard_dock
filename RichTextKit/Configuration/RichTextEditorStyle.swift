import UIKit
import SwiftUI

/// 字符数限制配置（放在 RichTextKit 命名空间中以避免与其他模块的类型冲突）
extension RichTextKit {
    public struct CharacterLimitConfig {
        /// 最大字符数
        public let maxCount: Int
        /// 超出限制时的回调（参数为尝试输入后的字符数）
        public let onExceeded: (Int) -> Void
        
        public init(maxCount: Int, onExceeded: @escaping (Int) -> Void) {
            self.maxCount = maxCount
            self.onExceeded = onExceeded
        }
    }
}

/// RichTextEditor 的 UI 样式配置
public struct RichTextEditorStyle {
    /// 占位符文本
    public var placeholder: String
    /// 字体
    public var font: UIFont
    /// 文本颜色
    public var textColor: UIColor
    /// 占位符颜色
    public var placeholderTextColor: UIColor
    /// 文本内边距
    public var textInsets: UIEdgeInsets
    /// 是否启用 YYText 高亮 tapAction（关闭则仅依赖外部手势）
    public var useYYTextHighlightTap: Bool
    /// 最大高度限制（nil 表示不限制）
    public var maxHeight: CGFloat?
    /// 字符数限制配置（nil 表示不限制）
    public var characterLimit: RichTextKit.CharacterLimitConfig?
    /// 键盘外观样式
    public var keyboardAppearance: UIKeyboardAppearance
    /// Token 点击回调
    public var onTokenTap: ((RichTextItem) -> Void)?
    /// 非 Token 区域点击回调（只读模式下使用）
    public var onNonTokenTap: (() -> Void)?
    
    public init(
        placeholder: String = "请输入内容...",
        font: UIFont = .systemFont(ofSize: 16),
        textColor: UIColor = .label,
        placeholderTextColor: UIColor = .placeholderText,
        maxHeight: CGFloat? = nil,
        characterLimit: RichTextKit.CharacterLimitConfig? = nil,
        keyboardAppearance: UIKeyboardAppearance = .default,
        onTokenTap: ((RichTextItem) -> Void)? = nil,
        onNonTokenTap: (() -> Void)? = nil,
        textInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8),
        useYYTextHighlightTap: Bool = false
    ) {
        self.placeholder = placeholder
        self.font = font
        self.textColor = textColor
        self.placeholderTextColor = placeholderTextColor
        self.textInsets = textInsets
        self.useYYTextHighlightTap = useYYTextHighlightTap
        self.maxHeight = maxHeight
        self.characterLimit = characterLimit
        self.keyboardAppearance = keyboardAppearance
        self.onTokenTap = onTokenTap
        self.onNonTokenTap = onNonTokenTap
    }
    
    public static var `default`: RichTextEditorStyle {
        RichTextEditorStyle()
    }
}
