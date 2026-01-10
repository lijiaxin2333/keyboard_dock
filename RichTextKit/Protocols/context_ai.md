# Protocols

作用
- 约束触发器与候选：`SuggestionItem`、`RichTextTrigger`。

核心能力/原理
- SuggestionItem：要求 id、displayName，业务候选需实现以供 dataBuilder 构建 RichTextItem。
- RichTextTrigger：定义触发符、tokenType、tokenFormat、tokenColor；`formatTokenText` 用占位 `{name}` 替换。

使用方式
```swift
struct Mention: SuggestionItem { let id: String; let displayName: String }
let trigger = MentionTrigger(tokenColor: .systemBlue)
let text = trigger.formatTokenText(item: Mention(id: "1", displayName: "Alice")) // "@Alice"
```


