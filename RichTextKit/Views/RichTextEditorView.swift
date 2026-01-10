import SwiftUI
import UIKit
import YYText
import Combine

/// RichTextKit 编辑器（仅负责编辑能力；候选面板由业务外部实现与注入）
public struct RichTextEditorView: View {
    
    @ObservedObject private var viewModel: RichTextEditorViewModel
    @State private var coordinator: RichTextEditorCoordinator?
    @State private var contentHeight: CGFloat = 17
    private let controlsKeyboardFocus: Bool
    @Binding private var isEditing: Bool
    @Binding private var insertString: String?
    private let onCoordinatorCreated: ((RichTextEditorCoordinator) -> Void)?
    private let tokenViewRegistry: RichTextTokenViewRegistry?
    private let renderer: RichTextAttributedTextRenderer
    
    public init(
        viewModel: RichTextEditorViewModel,
        isEditing: Binding<Bool>? = nil,
        insertString: Binding<String?> = .constant(nil),
        tokenViewRegistry: RichTextTokenViewRegistry? = nil,
        renderer: RichTextAttributedTextRenderer = RichTextAttributedTextRenderer(),
        onCoordinatorCreated: ((RichTextEditorCoordinator) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.controlsKeyboardFocus = (isEditing != nil)
        self._isEditing = isEditing ?? .constant(false)
        self._insertString = insertString
        self.tokenViewRegistry = tokenViewRegistry
        self.renderer = renderer
        self.onCoordinatorCreated = onCoordinatorCreated
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottom) {
                YYTextEditorRepresentable(
                    viewModel: viewModel,
                    placeholder: viewModel.editorConfig.placeholder,
                    font: viewModel.editorConfig.font,
                    textColor: viewModel.editorConfig.textColor,
                    maxHeight: viewModel.editorConfig.maxHeight,
                    characterLimit: viewModel.editorConfig.characterLimit,
                    keyboardAppearance: viewModel.editorConfig.keyboardAppearance,
                    tokenViewRegistry: tokenViewRegistry,
                    renderer: renderer,
                    controlsKeyboardFocus: controlsKeyboardFocus,
                    isEditing: $isEditing,
                    insertString: $insertString,
                    contentHeight: $contentHeight,
                    onCoordinatorCreated: { coordinator in
                        self.coordinator = coordinator
                        self.onCoordinatorCreated?(coordinator)
                    }
                )
                .frame(height: contentHeight)
                
                // 字符数统计 UI（仅在配置了 characterLimit 时显示）
                if let characterLimit = viewModel.editorConfig.characterLimit {
                    CharacterCountView(
                        currentCount: viewModel.content.plainText.count,
                        maxCount: characterLimit.maxCount
                    )
                    .padding(.top, 8)
                }
            }
        }
    }
}

struct YYTextEditorRepresentable: UIViewRepresentable {
    
    @ObservedObject var viewModel: RichTextEditorViewModel
    let placeholder: String
    let font: UIFont
    let textColor: UIColor
    let maxHeight: CGFloat?
    let characterLimit: RichTextKit.CharacterLimitConfig?
    let keyboardAppearance: UIKeyboardAppearance
    let tokenViewRegistry: RichTextTokenViewRegistry?
    let renderer: RichTextAttributedTextRenderer
    let controlsKeyboardFocus: Bool
    @Binding var isEditing: Bool
    @Binding var insertString: String?
    @Binding var contentHeight: CGFloat
    let onCoordinatorCreated: (RichTextEditorCoordinator) -> Void
    
    func makeUIView(context: Context) -> HeightReportingYYTextView {
        let textView = HeightReportingYYTextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = textColor
        textView.placeholderText = placeholder
        textView.placeholderFont = font
        textView.placeholderTextColor = viewModel.editorConfig.placeholderTextColor
        textView.backgroundColor = .clear
        textView.textContainerInset = viewModel.editorConfig.textInsets
        // 确保在只读模式下依然可点击高亮（token 点击依赖 highlightable/selectable）。
        textView.isSelectable = true
        textView.isHighlightable = true
        textView.isEditable = viewModel.isEditable
        textView.keyboardAppearance = keyboardAppearance
        // 初始禁用滚动，超出阈值后开启
        textView.isScrollEnabled = false
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        
        // 设置高度回调
        textView.onHeightChanged = { [weak textView] rawHeight in
            guard let textView = textView, textView.bounds.width > 0 else { return }
            let minH: CGFloat = 17
            let clamped = max(rawHeight, minH)
            let display = maxHeight.map { min(clamped, $0) } ?? clamped
            context.coordinator.onHeightChanged?(display)
            // 超出最大高度时启用滚动
            if let maxH = maxHeight {
                textView.isScrollEnabled = rawHeight > maxH
            } else {
                textView.isScrollEnabled = false
            }
        }
        
        context.coordinator.textView = textView
        context.coordinator.setupObservers()
        context.coordinator.isEditingBinding = controlsKeyboardFocus ? $isEditing : nil
        Task { @MainActor in
            onCoordinatorCreated(context.coordinator)
        }
        
        // 初始高度计算（在下一个 runloop 执行，确保布局完成）
        Task { @MainActor in
            let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
            textView.onHeightChanged?(size.height)
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: HeightReportingYYTextView, context: Context) {
        if uiView.isEditable != viewModel.isEditable {
            uiView.isEditable = viewModel.isEditable
        }
        
        // Update placeholder
        if uiView.placeholderText != placeholder {
            uiView.placeholderText = placeholder
        }
        if uiView.placeholderFont != font {
            uiView.placeholderFont = font
        }
        if uiView.placeholderTextColor != viewModel.editorConfig.placeholderTextColor {
            uiView.placeholderTextColor = viewModel.editorConfig.placeholderTextColor
        }
        
        // 更新键盘外观
        if uiView.keyboardAppearance != keyboardAppearance {
            uiView.keyboardAppearance = keyboardAppearance
        }
        
        // 更新字符限制配置
        context.coordinator.characterLimit = characterLimit
        context.coordinator.tokenViewRegistry = tokenViewRegistry
        context.coordinator.isEditingBinding = controlsKeyboardFocus ? $isEditing : nil

        // 外部控制键盘显示/隐藏
        if controlsKeyboardFocus {
            if isEditing {
                if !uiView.isFirstResponder && viewModel.isEditable {
                    Task { @MainActor in
                        _ = uiView.becomeFirstResponder()
                    }
                }
            } else {
                if uiView.isFirstResponder {
                    Task { @MainActor in
                        _ = uiView.resignFirstResponder()
                    }
                }
            }
        }

        if let stringToInsert = insertString, !stringToInsert.isEmpty {
            if context.coordinator.pendingInsertString == stringToInsert {
                return
            }
            context.coordinator.pendingInsertString = stringToInsert
            let token = UUID()
            context.coordinator.pendingInsertToken = token
            let insertBinding = _insertString
            Task { @MainActor in
                guard context.coordinator.pendingInsertToken == token else { return }
                context.coordinator.insertPlainText(stringToInsert)
                insertBinding.wrappedValue = nil
                context.coordinator.pendingInsertString = nil
                context.coordinator.pendingInsertToken = nil
            }
        } else if insertString == nil {
            if context.coordinator.pendingInsertString == nil {
                context.coordinator.lastInsertedString = nil
            }
        }
        
        // 维持高度回调
        uiView.onHeightChanged = { [weak uiView] rawHeight in
            guard let textView = uiView, textView.bounds.width > 0 else { return }
            let minH: CGFloat = 17
            let clamped = max(rawHeight, minH)
            let display = maxHeight.map { min(clamped, $0) } ?? clamped
            context.coordinator.onHeightChanged?(display)
            // 超出最大高度时启用滚动
            if let maxH = maxHeight {
                textView.isScrollEnabled = rawHeight > maxH
            } else {
                textView.isScrollEnabled = false
            }
        }
    }
    
    func makeCoordinator() -> RichTextEditorCoordinator {
        let coordinator = RichTextEditorCoordinator(
            viewModel: viewModel,
            font: font,
            contentHeight: $contentHeight,
            tokenViewRegistry: tokenViewRegistry,
            renderer: renderer
        )
        coordinator.characterLimit = characterLimit
        coordinator.isEditingBinding = controlsKeyboardFocus ? $isEditing : nil
        return coordinator
    }
}

public final class RichTextEditorCoordinator: NSObject, YYTextViewDelegate {
    
    weak var textView: YYTextView?
    private let viewModel: RichTextEditorViewModel
    private let font: UIFont
    @Binding private var contentHeight: CGFloat
    private var cancellables = Set<AnyCancellable>()
    private weak var tokenTapGesture: UITapGestureRecognizer?
    private var suppressTextViewDidChangeDepth: Int = 0
    
    var onHeightChanged: ((CGFloat) -> Void)?
    var characterLimit: RichTextKit.CharacterLimitConfig?
    var tokenViewRegistry: RichTextTokenViewRegistry?
    private let renderer: RichTextAttributedTextRenderer
    fileprivate var lastInsertedString: String?
    fileprivate var pendingInsertString: String?
    fileprivate var pendingInsertToken: UUID?
    var isEditingBinding: Binding<Bool>?
    private var pendingDeleteConfirmRange: NSRange?
    
    init(
        viewModel: RichTextEditorViewModel,
        font: UIFont,
        contentHeight: Binding<CGFloat>,
        tokenViewRegistry: RichTextTokenViewRegistry?,
        renderer: RichTextAttributedTextRenderer
    ) {
        self.viewModel = viewModel
        self.font = font
        self._contentHeight = contentHeight
        self.tokenViewRegistry = tokenViewRegistry
        self.renderer = renderer
        
        super.init()
        
        // 设置高度变化回调（仅在变化超过 2pt 时更新，避免频繁重渲染）
        self.onHeightChanged = { [weak self] height in
            guard let self = self else { return }
            let newHeight = max(17, height)
            if abs(newHeight - self.contentHeight) > 2 {
                Task { @MainActor in
                    self.contentHeight = newHeight
                }
            }
        }
    }
    
    func setupObservers() {
        viewModel.$pendingContent
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] content in
                self?.applyPendingContent(content)
            }
            .store(in: &cancellables)

        viewModel.$pendingInsertTokenCommand
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cmd in
                guard let self else { return }
                Task { @MainActor in
                    switch cmd.mode {
                    case .replaceTrigger:
                        self.insertToken(item: cmd.item, trigger: cmd.trigger)
                    case .atCursor:
                        self.insertTokenAtCursor(item: cmd.item, trigger: cmd.trigger)
                    }
                    self.viewModel.clearPendingInsertTokenCommand()
                }
            }
            .store(in: &cancellables)
        
        setupTokenTapGestureIfNeeded()
    }

    private func setupTokenTapGestureIfNeeded() {
        guard let textView, tokenTapGesture == nil else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTokenTap(_:)))
        tap.cancelsTouchesInView = false
        textView.addGestureRecognizer(tap)
        tokenTapGesture = tap
    }

    @objc private func handleTokenTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let textView else { return }
        guard let attributedText = textView.attributedText, attributedText.length > 0 else { return }
        guard let layout = textView.textLayout else { return }

        let locationInView = gesture.location(in: textView)
        // YYTextView 内部使用 containerView 坐标；在 UIScrollView 场景下需要加上 contentOffset。
        let pointInContainer = CGPoint(
            x: locationInView.x + textView.contentOffset.x,
            y: locationInView.y + textView.contentOffset.y
        )

        guard let textRange = layout.textRange(at: pointInContainer) ?? layout.closestTextRange(at: pointInContainer) else { return }
        let index = textRange.start.offset
        guard index != NSNotFound else { return }
        if let item = resolveToken(at: index, attributedText: attributedText) {
            viewModel.handleTokenTap(item: item)
        } else {
            if let onNonTokenTap = viewModel.editorConfig.onNonTokenTap {
                Task { @MainActor in
                    onNonTokenTap()
                }
            } else if viewModel.isEditable {
                viewModel.dismissSuggestionPanel()
            }
        }
    }
    
    private func resolveToken(at index: Int, attributedText: NSAttributedString) -> RichTextItem? {
        guard index >= 0, index < attributedText.length else { return nil }
        var effective = NSRange(location: 0, length: 0)
        let attrs = attributedText.attributes(at: index, effectiveRange: &effective)
        guard
            let type = attrs[.richTextItemType] as? String,
            let id = attrs[.richTextItemId] as? String
        else { return nil }
        
        let payload = attrs[.richTextItemPayload] as? String
        let displayText: String
        if let stored = attrs[.richTextItemDisplayText] as? String, !stored.isEmpty {
            displayText = stored
        } else {
            displayText = (attributedText.string as NSString).substring(with: effective)
        }
        return RichTextItem(type: type, displayText: displayText, data: id, payload: payload)
    }
    
    private func applyPendingContent(_ content: RichTextContent) {
        guard let textView = textView else { return }

        let attributedText = renderer.render(
            content: content,
            configuration: viewModel.getConfiguration(),
            editorConfig: viewModel.editorConfig,
            tokenViewRegistry: tokenViewRegistry,
            onTokenTap: { [weak viewModel] item in
                viewModel?.handleTokenTap(item: item)
            }
        )

        withSuppressedTextViewDidChange {
            textView.attributedText = attributedText
            textView.selectedRange = NSRange(location: attributedText.length, length: 0)
        }
        resetTypingAttributes(textView)
        if attributedText.length == 0 {
            viewModel.dismissSuggestionPanel()
        }
        viewModel.clearPendingContent()
        viewModel.textDidChange(textView.attributedText ?? NSAttributedString())
        // 应用内容后更新高度
        updateHeight(for: textView)
        scrollSelectionIntoView()
    }
    
    public func textView(_ textView: YYTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let (allowed, safeRange, currentAttr) = evaluateInputChange(requestedRange: range, replacementText: text)
        guard allowed else { return false }
        if text.isEmpty, safeRange.length > 0 {
            // 多选删除：直接允许批量删除，避免逐个 token 确认导致只删首个
            if safeRange.length > 1 {
                pendingDeleteConfirmRange = nil
                return true
            }
            let nsText = currentAttr.string as NSString
            let maxLen = nsText.length

            func isWhitespace(range: NSRange) -> Bool {
                if range.location < 0 || range.length <= 0 { return false }
                if range.location + range.length > maxLen { return false }
                let s = nsText.substring(with: range)
                return s.unicodeScalars.allSatisfy { CharacterSet.whitespacesAndNewlines.contains($0) }
            }

            func bindingRangeHit(by r: NSRange) -> NSRange? {
                deleteConfirmBindingRange(in: currentAttr, for: r)
            }

            var tokenRange: NSRange?
            if let r = bindingRangeHit(by: safeRange) {
                tokenRange = r
            } else if safeRange.length == 1, safeRange.location > 0, isWhitespace(range: safeRange) {
                let left = NSRange(location: safeRange.location - 1, length: 1)
                tokenRange = bindingRangeHit(by: left)
            }

            if var tokenRange {
                var confirmRange = tokenRange
                if safeRange.length == 1,
                   isWhitespace(range: safeRange),
                   safeRange.location == tokenRange.location + tokenRange.length {
                    confirmRange = NSRange(location: tokenRange.location, length: tokenRange.length + safeRange.length)
                }

                if let pending = pendingDeleteConfirmRange, rangesIntersect(pending, tokenRange) {
                    let target = pending
                    pendingDeleteConfirmRange = nil
                    if NSEqualRanges(safeRange, target) {
                        return true
                    }
                    deleteRangeProgrammatically(target)
                    return false
                }

                pendingDeleteConfirmRange = confirmRange
                if NSEqualRanges(textView.selectedRange, confirmRange) == false {
                    textView.selectedRange = confirmRange
                }
                return false
            }
        }
        pendingDeleteConfirmRange = nil
        return true
    }
    
    public func textViewDidChange(_ textView: YYTextView) {
        pendingDeleteConfirmRange = nil
        if suppressTextViewDidChangeDepth > 0 {
            return
        }
        if (textView.attributedText?.length ?? 0) == 0 {
            viewModel.dismissSuggestionPanel()
        }
        viewModel.textDidChange(textView.attributedText ?? NSAttributedString())
        // 内容变化时更新高度
        updateHeight(for: textView)
    }

    public func textViewDidChangeSelection(_ textView: YYTextView) {
        if let pending = pendingDeleteConfirmRange,
           rangesIntersect(textView.selectedRange, pending) == false {
            pendingDeleteConfirmRange = nil
        }
        resetTypingAttributesIfNeededForTokenBoundary(textView)
    }

    public func textViewDidBeginEditing(_ textView: YYTextView) {
        guard isEditingBinding?.wrappedValue != true else { return }
        Task { @MainActor [weak self] in
            self?.isEditingBinding?.wrappedValue = true
        }
    }

    public func textViewDidEndEditing(_ textView: YYTextView) {
        guard isEditingBinding?.wrappedValue != false else { return }
        Task { @MainActor [weak self] in
            self?.isEditingBinding?.wrappedValue = false
        }
    }
    
    private func updateHeight(for textView: YYTextView) {
        let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
        (textView as? HeightReportingYYTextView)?.onHeightChanged?(size.height)
    }
    
    @MainActor
    public func insertToken(item: any SuggestionItem, trigger: RichTextTrigger) {
        guard let textView = textView else { return }
        let currentText = (textView.attributedText ?? NSAttributedString()).string as NSString
        let maxLen = currentText.length
        let selectionEnd = min(max(0, textView.selectedRange.location), maxLen)
        let triggerString = trigger.triggerCharacter
        
        var start = min(max(0, viewModel.getTriggerLocation()), maxLen)
        if triggerString.isEmpty == false {
            if start < maxLen {
                let s = currentText.substring(with: NSRange(location: start, length: 1))
                if s != triggerString {
                    insertTokenAtCursor(item: item, trigger: trigger)
                    return
                }
            } else {
                insertTokenAtCursor(item: item, trigger: trigger)
                return
            }
            
            if start == maxLen {
                var i = max(0, selectionEnd - 1)
                while i >= 0 {
                    let c = currentText.substring(with: NSRange(location: i, length: 1))
                    if c == triggerString {
                        start = i
                        break
                    }
                    if c == " " || c == "\n" || c == "\t" { break }
                    i -= 1
                }
                if start == maxLen {
                    insertTokenAtCursor(item: item, trigger: trigger)
                    return
                }
            }
        }
        
        if start >= maxLen {
            insertTokenAtCursor(item: item, trigger: trigger)
            return
        }
        
        let keywordLen = (viewModel.searchKeyword as NSString).length
        let composingEnd = min(maxLen, start + 1 + keywordLen)
        let end = max(selectionEnd, composingEnd)
        let safeLength = max(0, min(maxLen - start, end - start))
        let rangeToReplace = NSRange(location: start, length: safeLength)
        let triggerLocation = start
        
        let richItem = viewModel.buildRichTextItem(from: item, trigger: trigger)
        let token = renderer.tokenAttributedString(
            item: richItem,
            trigger: trigger,
            font: font,
            editorConfig: viewModel.editorConfig,
            configuration: viewModel.getConfiguration(),
            tokenViewRegistry: tokenViewRegistry,
            onTokenTap: { [weak viewModel] item in
                viewModel?.handleTokenTap(item: item)
            }
        )
        let tokenLength = token.length
        let insert = NSMutableAttributedString(attributedString: token)
        if shouldAppendTokenSeparator(originalText: currentText, originalNextIndex: rangeToReplace.location + rangeToReplace.length) {
            insert.append(makeTokenSeparatorAttributedString())
        }
        
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
        mutable.replaceCharacters(in: rangeToReplace, with: insert)
        
        let binding = YYTextBinding(deleteConfirm: true)
        if tokenLength > 0 {
            mutable.yy_setTextBinding(binding, range: NSRange(location: triggerLocation, length: tokenLength))
        }
        
        withSuppressedTextViewDidChange {
            textView.attributedText = mutable
            textView.selectedRange = NSRange(location: triggerLocation + insert.length, length: 0)
        }
        resetTypingAttributes(textView)
        viewModel.dismissSuggestionPanel()
        viewModel.textDidChange(textView.attributedText ?? NSAttributedString())
        // 插入 token 后更新高度
        updateHeight(for: textView)
        scrollSelectionIntoView()
    }

    /// 在当前光标/选区位置插入 token（不依赖 triggerLocation），用于外部直接注入 mention/topic。
    @MainActor
    public func insertTokenAtCursor(item: any SuggestionItem, trigger: RichTextTrigger) {
        guard let textView = textView else { return }

        let rangeToReplace = textView.selectedRange
        let currentText = (textView.attributedText ?? NSAttributedString()).string as NSString
        let richItem = viewModel.buildRichTextItem(from: item, trigger: trigger)
        let token = renderer.tokenAttributedString(
            item: richItem,
            trigger: trigger,
            font: font,
            editorConfig: viewModel.editorConfig,
            configuration: viewModel.getConfiguration(),
            tokenViewRegistry: tokenViewRegistry,
            onTokenTap: { [weak viewModel] item in
                viewModel?.handleTokenTap(item: item)
            }
        )
        let tokenLength = token.length
        let insert = NSMutableAttributedString(attributedString: token)
        if shouldAppendTokenSeparator(originalText: currentText, originalNextIndex: rangeToReplace.location + rangeToReplace.length) {
            insert.append(makeTokenSeparatorAttributedString())
        }

        let mutable = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
        mutable.replaceCharacters(in: rangeToReplace, with: insert)

        if tokenLength > 0 {
            mutable.yy_setTextBinding(
                YYTextBinding(deleteConfirm: true),
                range: NSRange(location: rangeToReplace.location, length: tokenLength)
            )
        }

        withSuppressedTextViewDidChange {
            textView.attributedText = mutable
            textView.selectedRange = NSRange(location: rangeToReplace.location + insert.length, length: 0)
        }
        resetTypingAttributes(textView)
        viewModel.dismissSuggestionPanel()
        viewModel.textDidChange(textView.attributedText ?? NSAttributedString())
        updateHeight(for: textView)
        scrollSelectionIntoView()
    }

    private func shouldAppendTokenSeparator(originalText: NSString, originalNextIndex: Int) -> Bool {
        if originalNextIndex < 0 { return true }
        if originalNextIndex >= originalText.length { return true }
        let next = originalText.substring(with: NSRange(location: originalNextIndex, length: 1))
        if next == " " || next == "\n" || next == "\t" { return false }
        if next.unicodeScalars.allSatisfy({ CharacterSet.punctuationCharacters.contains($0) }) { return false }
        if "，。！？、；：）】》」".contains(next) { return false }
        return true
    }

    private func makeTokenSeparatorAttributedString() -> NSAttributedString {
        NSAttributedString(
            string: " ",
            attributes: [
                .font: font,
                .foregroundColor: viewModel.editorConfig.textColor
            ]
        )
    }

    private func withSuppressedTextViewDidChange(_ work: () -> Void) {
        suppressTextViewDidChangeDepth += 1
        work()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.suppressTextViewDidChangeDepth = max(0, self.suppressTextViewDidChangeDepth - 1)
        }
    }

    /// 外部插入纯文本（例如点击按钮插入 "@"），支持去重保护。
    func insertPlainText(_ string: String) {
        guard let textView else { return }
        let currentRange = textView.selectedRange
        let (allowed, safeRange, _) = evaluateInputChange(requestedRange: currentRange, replacementText: string)
        if allowed == false { return }
        if lastInsertedString == string { return }
        lastInsertedString = string

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: viewModel.editorConfig.textColor
        ]
        let insert = NSAttributedString(string: string, attributes: attrs)
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
        mutable.replaceCharacters(in: safeRange, with: insert)

        withSuppressedTextViewDidChange {
            textView.attributedText = mutable
            textView.selectedRange = NSRange(
                location: safeRange.location + (string as NSString).length,
                length: 0
            )
        }

        resetTypingAttributes(textView)
        viewModel.textDidChange(textView.attributedText ?? NSAttributedString())
        updateHeight(for: textView)
        scrollSelectionIntoView()
    }

    private func evaluateInputChange(
        requestedRange: NSRange,
        replacementText text: String
    ) -> (allowed: Bool, safeRange: NSRange, currentAttr: NSAttributedString) {
        guard let textView else {
            return (false, requestedRange, NSAttributedString())
        }
        let currentAttr = textView.attributedText ?? NSAttributedString()
        let nsText = currentAttr.string as NSString
        let maxLen = nsText.length
        var safeRange = requestedRange
        if safeRange.location < 0 { safeRange.location = 0 }
        if safeRange.length < 0 { safeRange.length = 0 }
        if safeRange.location > maxLen {
            safeRange = NSRange(location: maxLen, length: 0)
        } else if safeRange.location + safeRange.length > maxLen {
            safeRange.length = max(0, maxLen - safeRange.location)
        }
        if let limit = characterLimit, !text.isEmpty {
            let currentLength = viewModel.content.plainText.count
            let removedLength = logicalLength(of: safeRange, in: currentAttr)
            let insertLength = text.count
            let newLength = currentLength - removedLength + insertLength
            if newLength > limit.maxCount {
                limit.onExceeded(newLength)
                return (false, safeRange, currentAttr)
            }
        }
        let allowed = viewModel.shouldChangeText(in: safeRange, replacementText: text, currentText: currentAttr)
        return (allowed, safeRange, currentAttr)
    }

    private func logicalLength(of range: NSRange, in attributedText: NSAttributedString) -> Int {
        guard attributedText.length > 0 else { return 0 }
        let clamped = NSRange(
            location: max(0, min(range.location, attributedText.length)),
            length: max(0, min(range.length, max(0, attributedText.length - range.location)))
        )
        if clamped.length == 0 { return 0 }
        var length = 0
        attributedText.enumerateAttributes(in: clamped) { attrs, subRange, _ in
            if let _ = attrs[.richTextItemType] as? String,
               let _ = attrs[.richTextItemId] as? String {
                let rangeText = (attributedText.string as NSString).substring(with: subRange)
                let storedText = attrs[.richTextItemDisplayText] as? String
                let displayText = (rangeText == "\u{FFFC}") ? (storedText ?? "") : rangeText
                length += displayText.count
            } else {
                let text = (attributedText.string as NSString).substring(with: subRange)
                length += text.count
            }
        }
        return length
    }

    private func deleteConfirmBindingRange(in text: NSAttributedString, for range: NSRange) -> NSRange? {
        guard text.length > 0 else { return nil }
        let index = min(max(range.location, 0), text.length - 1)
        var effective = NSRange(location: 0, length: 0)
        let key = NSAttributedString.Key(YYTextBindingAttributeName)
        guard let binding = text.attribute(key, at: index, longestEffectiveRange: &effective, in: NSRange(location: 0, length: text.length)) as? YYTextBinding,
              binding.deleteConfirm,
              effective.length > 0 else {
            return nil
        }
        return effective
    }

    private func rangesIntersect(_ a: NSRange, _ b: NSRange) -> Bool {
        let aEnd = a.location + a.length
        let bEnd = b.location + b.length
        if a.length == 0 || b.length == 0 { return false }
        return max(a.location, b.location) < min(aEnd, bEnd)
    }

    private func deleteRangeProgrammatically(_ range: NSRange) {
        guard let textView else { return }
        let current = textView.attributedText ?? NSAttributedString()
        if range.location < 0 || range.length <= 0 { return }
        if range.location + range.length > current.length { return }
        let mutable = NSMutableAttributedString(attributedString: current)
        mutable.replaceCharacters(in: range, with: NSAttributedString(string: ""))
        withSuppressedTextViewDidChange {
            textView.attributedText = mutable
            textView.selectedRange = NSRange(location: range.location, length: 0)
        }
        resetTypingAttributes(textView)
        if mutable.length == 0 {
            viewModel.dismissSuggestionPanel()
        }
        viewModel.textDidChange(textView.attributedText ?? NSAttributedString())
        updateHeight(for: textView)
        scrollSelectionIntoView()
    }
    
    @MainActor
    private func scrollSelectionIntoView() {
        guard let textView, viewModel.isEditable else { return }
        textView.scrollRangeToVisible(textView.selectedRange)
    }
    
    func resetTypingAttributes(_ textView: YYTextView) {
        textView.typingAttributes = [
            NSAttributedString.Key.font.rawValue: font,
            NSAttributedString.Key.foregroundColor.rawValue: viewModel.editorConfig.textColor
        ]
    }

    private func resetTypingAttributesIfNeededForTokenBoundary(_ textView: YYTextView) {
        if textView.selectedRange.length != 0 { return }
        guard let attr = textView.attributedText, attr.length > 0 else { return }
        let location = min(max(0, textView.selectedRange.location), attr.length)
        let leftIndex = max(0, min(attr.length - 1, location - 1))
        let rightIndex = max(0, min(attr.length - 1, location))
        let leftAttrs = attr.attributes(at: leftIndex, effectiveRange: nil)
        let rightAttrs = attr.attributes(at: rightIndex, effectiveRange: nil)
        let hasTokenAttrs =
            (leftAttrs[.richTextItemType] != nil && leftAttrs[.richTextItemId] != nil) ||
            (rightAttrs[.richTextItemType] != nil && rightAttrs[.richTextItemId] != nil) ||
            (leftAttrs[NSAttributedString.Key(YYTextBindingAttributeName)] != nil) ||
            (rightAttrs[NSAttributedString.Key(YYTextBindingAttributeName)] != nil)
        if hasTokenAttrs {
            resetTypingAttributes(textView)
        }
    }
}

// MARK: - 字符数统计 UI

private struct CharacterCountView: View {
    let currentCount: Int
    let maxCount: Int
    
    private var isExceeded: Bool {
        currentCount > maxCount
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            Text("\(currentCount)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isExceeded ? Color(hex: "FF5B5B") : Color(hex: "8F8F8F"))
            Text("/\(maxCount)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "8F8F8F"))
        }
        .padding(.trailing, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - 自适应高度支持

/// 自定义 YYTextView，用于标记需要高度回调的 TextView
final class HeightReportingYYTextView: YYTextView {
    var onHeightChanged: ((CGFloat) -> Void)?
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 每次布局变化时计算并上报高度
        guard bounds.width > 0 else { return }
        let size = sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
        onHeightChanged?(size.height)
    }
}
