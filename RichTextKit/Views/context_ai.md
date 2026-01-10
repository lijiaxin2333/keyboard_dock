# Views

作用
|- SwiftUI 包装编辑器入口：`RichTextEditorView`。
|- UIKit 桥接：`YYTextEditorRepresentable` 内部协调器处理输入、插入、点击、滚动与高度自适应。
|- Token 视图注册：`RichTextTokenViewRegistry` 提供 type->SwiftUI 视图映射。

核心能力/原理
|- RichTextEditorView：接受 ViewModel、可选键盘控制、外部插入字符串、token 渲染 registry、renderer。
|- 协调器（RichTextEditorCoordinator）：YYTextViewDelegate，负责字符限制、组合态输入、程序化插入 token/纯文本、删除保护、点击命中、滚动与高度计算。
|- 点击收敛：统一通过手势命中 token attributes，调用 ViewModel.handleTokenTap。
|- 高度自适应：HeightReportingYYTextView sizeThatFits 回调 + maxHeight 触发滚动。

使用方式
```swift
@StateObject var vm = RichTextEditorViewModel(configuration: config, editorConfig: editorConfig)
let registry = RichTextTokenViewRegistry.typed(type: "mention") { (_: RichTextItem, payload: MentionPayload, _: UIFont) in
    RichTextTokenView(Text(payload.name))
}
RichTextEditorView(viewModel: vm, isEditing: $isEditing, insertString: $insertString, tokenViewRegistry: registry)
```

## Android 差异（展开/收起，只读态）
|- 需求：仅 `RichTextView` 支持展开/收起，`RichEditText` 不接入。
|- 实现要点：只读渲染阶段在末尾追加 `ExpandToggleMark(mode: Expand/Collapse)`，溢出判定基于高度/行数/折叠字符阈值；收起态追加 `...` + 展开标记，展开态追加收起标记。
|- 配置：`CollapseConfig`（只读）含 `collapsedMaxHeight|collapsedMaxLines|collapsedMaxCharacters|expandText|collapseText|toggleStyle|initialExpanded`，默认 null 不启用，`toggleStyle` 应用到 Toggle span（无下划线，兜底 linkColor）。
|- 状态：已完成实现，详见 `android-richtext-expand-collapse.md`。

### 展开/收起设计差异对比

| 维度 | iOS（方案 B） | Android（方案 A） | 优势 |
|------|---------------|-------------------|------|
| **类型数量** | 2 个字符串类型：`_expand` 和 `_collapse` | 1 个类 + 枚举：`ExpandToggleMark(Mode)` | ✅ Android |
| **类型安全** | ❌ 字符串（易拼写错误） | ✅ 枚举（编译期检查） | ✅ Android |
| **配置数量** | ❌ 需要注册两次 `registerToken` | ✅ 一个配置 `CollapseConfig` | ✅ Android |
| **状态管理** | 分散在 token 配置的 `onTap` 回调 | 集中在 ViewModel (`isExpandedFlow`) | ✅ Android |
| **代码重复** | ❌ 高（两个几乎相同的配置） | ✅ 低（一个配置） | ✅ Android |
| **扩展性** | 需要新增类型 | 扩展枚举即可 | ✅ Android |
| **简单直观** | ✅ 每个类型对应明确行为 | ✅ 状态逻辑清晰 | 平手 |

**对齐建议：** Android 的方案 A（单一类型 + 枚举）更优，推荐 iOS 未来改造时参考。
