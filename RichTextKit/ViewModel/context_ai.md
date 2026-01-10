# ViewModel

作用
- 维护编辑状态：`content`、`activeTrigger`、`searchKeyword`、`pendingContent`、`pendingInsertTokenCommand`、`isEditable`。
- 处理输入、组合态、外部插入，解析 TextView 富文本回写为模型。

核心能力/原理
- `shouldChangeText`：检测触发符，更新 `activeTrigger/searchKeyword`；空格/换行/回删到触发符前会关闭组合态。
- `textDidChange`：遍历 attributedText 按自定义 attributes 解析为 `RichTextContent` 并写入 `content`。
- 外部内容注入：`setContent/clearContent` 仅设 `pendingContent`，由协调器渲染后再回写。
- 外部插入 token：`insertToken`（组合态替换触发段）与 `insertTokenAtCursor`（光标插入）通过 `pendingInsertTokenCommand` 驱动协调器。
- token 点击分发：优先 `RichTextTokenConfig.onTap`，否则全局 `onTokenTap`。

使用方式
```swift
let vm = RichTextEditorViewModel(configuration: config, editorConfig: editorConfig)
vm.$activeTrigger.combineLatest(vm.$searchKeyword) { trigger, keyword in ... } // 驱动面板
vm.setContent(content) // 外部设置
vm.insertTokenAtCursor(item: suggestion, trigger: MentionTrigger())
```
