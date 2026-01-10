import SwiftUI
import YYText

public struct RichTextExpandableReadOnlyView: View {
    @StateObject private var state: ExpandableState
    
    @ObservedObject private var viewModel: RichTextEditorViewModel
    private let baseContent: RichTextContent
    private let tokenViewRegistry: RichTextTokenViewRegistry?
    private let collapsedMaxHeight: CGFloat?
    private let expandText: String
    private let collapseText: String
    private let toggleTextColor: Color
    private let onNonTokenTap: (() -> Void)?
    private let onExpandStateChange: ((Bool) -> Void)?
    private let renderer = RichTextAttributedTextRenderer()

    public init(
        viewModel: RichTextEditorViewModel,
        baseContent: RichTextContent,
        tokenViewRegistry: RichTextTokenViewRegistry?,
        collapsedMaxHeight: CGFloat? = nil,
        expandText: String = "...展开",
        collapseText: String = " 收起",
        toggleTextColor: Color = .white,
        onNonTokenTap: (() -> Void)? = nil,
        onExpandStateChange: ((Bool) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.baseContent = baseContent
        self.tokenViewRegistry = tokenViewRegistry
        self.collapsedMaxHeight = collapsedMaxHeight
        self.expandText = expandText
        self.collapseText = collapseText
        self.toggleTextColor = toggleTextColor
        self.onNonTokenTap = onNonTokenTap
        self.onExpandStateChange = onExpandStateChange
        
        let stateInstance = ExpandableState()
        _state = StateObject(wrappedValue: stateInstance)
        
        if let onNonTokenTap = onNonTokenTap {
            viewModel.editorConfig.onNonTokenTap = onNonTokenTap
        }
        
        let baseFont = viewModel.editorConfig.font
        let boldFont = UIFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.traitBold) ?? baseFont.fontDescriptor, size: baseFont.pointSize)
        
        let expandTrigger = SimpleTrigger(tokenType: "_expand", tokenColor: UIColor(toggleTextColor), tokenFont: boldFont)
        let collapseTrigger = SimpleTrigger(tokenType: "_collapse", tokenColor: UIColor(toggleTextColor), tokenFont: boldFont)
        viewModel.getConfiguration().register(expandTrigger)
        viewModel.getConfiguration().register(collapseTrigger)
    }

    public var body: some View {
        RichTextEditorView(
            viewModel: viewModel,
            tokenViewRegistry: mergedRegistry
        )
        .fixedSize(horizontal: false, vertical: true)
        .overlay(widthReader)
        .onPreferenceChange(ExpandableWidthKey.self) { width in
            guard width > 0 else { return }
            if abs(width - state.availableWidth) < 0.5 { return }
            state.availableWidth = width
            Task { @MainActor in
                calculateAndApplyContent(width: width, isExpanded: state.isExpanded)
            }
        }
        .onReceive(state.$isExpanded) { isExpanded in
            if state.availableWidth > 0 {
                calculateAndApplyContent(width: state.availableWidth, isExpanded: isExpanded)
            }
            onExpandStateChange?(isExpanded)
        }
        .onAppear {
            registerTokens()
            viewModel.isEditable = false
            viewModel.setContent(baseContent)
            if state.availableWidth > 0 {
                calculateAndApplyContent(width: state.availableWidth, isExpanded: state.isExpanded)
            }
        }
        .onChange(of: baseContent) { newContent in
            // 异步执行，确保 View 更新周期正确
            Task { @MainActor in
                if state.availableWidth > 0 {
                    // 如果宽度已知，直接计算并应用截断后的内容
                    calculateAndApplyContent(width: state.availableWidth, isExpanded: state.isExpanded)
                } else {
                    // 宽度未知时，先设置原始内容，避免空白
                    viewModel.setContent(newContent)
                }
            }
        }
    }

    private var widthReader: some View {
        GeometryReader { geo in
            Color.clear.preference(key: ExpandableWidthKey.self, value: geo.size.width)
        }
    }

    private var shouldTruncate: Bool {
        guard let collapsedMaxHeight else { return false }
        return state.fullContentHeight > collapsedMaxHeight + 1
    }

    private var mergedRegistry: RichTextTokenViewRegistry? {
        tokenViewRegistry
    }
    
    private struct SimpleTrigger: RichTextTrigger, @unchecked Sendable {
        var triggerCharacter: String { tokenType }
        let tokenType: String
        let tokenFormat: String = ""
        let tokenColor: UIColor
        let tokenFont: UIFont?
    }

    private func registerTokens() {
        viewModel.getConfiguration().registerToken(
            type: "_expand",
            config: RichTextTokenConfig(
                dataBuilder: { [expandText] _ in RichTextItem(type: "_expand", displayText: expandText, data: "_expand") },
                onTap: { [state] _ in
                    Task { @MainActor in
                        state.isExpanded = true
                    }
                }
            )
        )
        viewModel.getConfiguration().registerToken(
            type: "_collapse",
            config: RichTextTokenConfig(
                dataBuilder: { [collapseText] _ in RichTextItem(type: "_collapse", displayText: collapseText, data: "_collapse") },
                onTap: { [state] _ in
                    Task { @MainActor in
                        state.isExpanded = false
                    }
                }
            )
        )
    }

    private func calculateAndApplyContent(width: CGFloat, isExpanded: Bool) {
        let fullAttributedText = renderer.render(
            content: baseContent,
            configuration: viewModel.getConfiguration(),
            editorConfig: viewModel.editorConfig,
            tokenViewRegistry: mergedRegistry,
            onTokenTap: { _ in }
        )
        let containerSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let container = YYTextContainer(size: containerSize)
        container.insets = viewModel.editorConfig.textInsets
        let layout = YYTextLayout(container: container, text: fullAttributedText)
        let fullHeight = ceil(layout?.textBoundingSize.height ?? 0)
        state.fullContentHeight = fullHeight
        
        guard let collapsedMaxHeight else {
            viewModel.isEditable = false
            viewModel.setContent(baseContent)
            return
        }
        
        let needsTruncation = fullHeight > collapsedMaxHeight + 1
        
        if !needsTruncation {
            viewModel.isEditable = false
            viewModel.setContent(baseContent)
            return
        }
        
        if isExpanded {
            var expandedItems = baseContent.items
            expandedItems.append(RichTextItem(type: "_collapse", displayText: collapseText, data: "_collapse"))
            viewModel.isEditable = false
            viewModel.setContent(RichTextContent(items: expandedItems))
        } else {
            let truncatedContent = truncateContent(
                fullText: fullAttributedText,
                width: width,
                maxHeight: collapsedMaxHeight
            )
            viewModel.isEditable = false
            viewModel.setContent(truncatedContent)
        }
    }
    
    private func truncateContent(fullText: NSAttributedString, width: CGFloat, maxHeight: CGFloat) -> RichTextContent {
        let container = YYTextContainer(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        container.insets = viewModel.editorConfig.textInsets
        guard let layout = YYTextLayout(container: container, text: fullText) else { return baseContent }
        
        let lines = layout.lines
        var currentHeight: CGFloat = 0
        var truncateLineIndex: Int = -1
        var heightFits = true
        
        for (index, line) in lines.enumerated() {
            if currentHeight + line.height > maxHeight {
                heightFits = false
                // 如果不是第一行，则回退到上一行截断
                if index > 0 {
                    truncateLineIndex = index - 1
                } else {
                    truncateLineIndex = 0
                }
                break
            }
            currentHeight += line.height
            truncateLineIndex = index
        }
        
        // 如果能完全显示，直接返回
        if heightFits {
            return baseContent
        }
        
        // 计算展开 token 的宽度
        let expandToken = renderer.render(
            content: RichTextContent(items: [RichTextItem(type: "_expand", displayText: expandText, data: "_expand")]),
            configuration: viewModel.getConfiguration(),
            editorConfig: viewModel.editorConfig,
            tokenViewRegistry: mergedRegistry,
            onTokenTap: { _ in }
        )
        let ellipsis = NSAttributedString(string: "...", attributes: [
            .font: viewModel.editorConfig.font,
            .foregroundColor: viewModel.editorConfig.textColor
        ])
        let suffix = NSMutableAttributedString(attributedString: ellipsis)
        suffix.append(expandToken)
        let suffixWidth = suffix.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil).width + 5
        
        // 在截断行寻找合适的切分点
        let line = lines[truncateLineIndex]
        let lineRange = line.range
        let lineText = fullText.attributedSubstring(from: lineRange)
        
        // 计算可用行宽
        let availableLineWidth = width - viewModel.editorConfig.textInsets.left - viewModel.editorConfig.textInsets.right
        
        // 二分查找切分点
        var low = 0
        var high = lineRange.length
        var bestCut = 0
        
        while low <= high {
            let mid = (low + high) / 2
            let sub = lineText.attributedSubstring(from: NSRange(location: 0, length: mid))
            // 计算宽度
            let w = sub.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil).width
            
            if w + suffixWidth <= availableLineWidth {
                bestCut = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        let finalIndex = lineRange.location + bestCut
        
        // 根据 finalIndex 切分 RichTextContent
        var truncatedItems: [RichTextItem] = []
        var currentIndex = 0
        
        for item in baseContent.items {
            let itemLen = item.displayText.utf16.count
            
            if currentIndex + itemLen <= finalIndex {
                truncatedItems.append(item)
                currentIndex += itemLen
            } else {
                // 切分点在这个 item 内
                if item.type == "text" {
                    let cutLen = finalIndex - currentIndex
                    if cutLen > 0 {
                        let text = item.displayText
                        // 需要处理 UTF-16 index 到 String index 的转换
                        if let range = Range(NSRange(location: 0, length: cutLen), in: text) {
                            let prefix = String(text[range])
                            truncatedItems.append(RichTextItem(type: "text", displayText: prefix, data: ""))
                        }
                    }
                }
                // 如果是 token，且只能显示一部分，直接丢弃
                break
            }
        }
        
        truncatedItems.append(RichTextItem(type: "_expand", displayText: expandText, data: "_expand"))
        return RichTextContent(items: truncatedItems)
    }
    
}

@MainActor
private final class ExpandableState: ObservableObject {
    @Published var isExpanded: Bool = false
    var fullContentHeight: CGFloat = 0
    var availableWidth: CGFloat = 0
}

private struct ExpandableWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


