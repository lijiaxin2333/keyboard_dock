# Models

作用
- 承载富文本结构化数据：`RichTextItem`、`RichTextContent`、`SuggestionItem`。
- 支持序列化、payload 回填、plainText 导出。

核心能力/原理
- RichTextItem：`type/displayText/data/payload`，payload 为 JSON 字符串；`text` 静态便捷工厂。
- RichTextContent：`items: [RichTextItem]` + `plainText` 拼接；`Codable` 用于草稿/服务端交互。
- PayloadBackfill：`content.backfillPayload(forType:payloadByData:)` 根据 data 补充缺失 payload。
- SuggestionItem 协议：id/displayName，供触发器与数据构建使用。

使用方式
```swift
let item = RichTextItem(type: "mention", displayText: "@Alice", data: "uid_1", payload: "{\"avatar\":\"...\"}")
let content = RichTextContent(items: [.text("Hi "), item])
let fixed = content.backfillPayload(forType: "mention", payloadByData: ["uid_1": MentionPayload(...)])
```


