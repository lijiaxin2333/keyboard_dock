# RichTextKit 技术文档

RichTextKit 用来做“可编辑的富文本输入”：文本 + token（`@提及`、`#话题#`）混排，并把点击、删除保护、字符限制、自适应高度这些能力打包好。


## 业务接入

你需要把三件事接起来：
- token 的**数据怎么来**（候选 -> `RichTextItem + payload`）
- token **长什么样**（`RichTextTokenViewRegistry` 渲染）
- 面板的**显示/选中**（业务自己做，编辑器只给 signal）

### 1) 配置 trigger 与 token 数据（候选 -> item/payload）

```swift
import UIComponentKit

let config = RichTextConfiguration()
config.register(
    MentionTrigger(
        tokenColor: .systemBlue
    )
)
config.register(TopicTrigger(tokenColor: .systemOrange))

config.registerToken(
    type: "mention",
    config: RichTextTokenConfig.typed(
        dataBuilder: { (s: YourMentionSuggestion) in
            let payload = YourMentionPayload(id: s.id, name: s.name, avatar: s.avatar)
            let item = RichTextItem(type: "mention", displayText: "@\(s.name)", data: s.id)
            return (item, payload)
        },
        onTap: { item, payload in
            handleMentionTap(item: item, payload: payload)
        }
    )
)
```

要点：
- `dataBuilder` 的参数 `s` 就是“你面板里那一条候选”（类型由业务定义，只要实现 `SuggestionItem`）。
- `dataBuilder` 负责把候选变成 `RichTextItem + payload`：`item` 用于序列化/解析，`payload` 用于渲染/点击（会自动编码进 `item.payload`）。
- `registerToken(type:config:)` 只做数据与点击，不做 UI；UI 渲染统一走 registry，避免数据层/视图层混在一起。
- 候选面板监听 `RichTextEditorViewModel` 的 `activeTrigger` 与 `searchKeyword` 变化来控制显示/请求。

### 2) 创建 EditorStyle

```swift
import UIComponentKit
import UIKit

let editorStyle = RichTextEditorStyle(
    placeholder: "请输入内容",
    font: .systemFont(ofSize: 16),
    textColor: .label,
    maxHeight: 200,
    characterLimit: RichTextKit.CharacterLimitConfig(
        maxCount: 500,
        onExceeded: { _ in
            showToast("已超出 500 字")
        }
    ),
    onTokenTap: { item in
        handleTokenTap(item)
    }
)
```

要点：
- `maxHeight` + 内部 `isScrollEnabled` 实现自适应高度上限。

### 3) 注入 token UI

```swift
import UIComponentKit
import SwiftUI

let tokenViewRegistry = RichTextTokenViewRegistry.typed(
    type: "mention",
    viewBuilder: { _, payload, _ in
        RichTextTokenView(
            Text(payload.name)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        )
    }
)
```

多类型 registry（一个 editor 渲染多种 token）：

```swift
import UIComponentKit
import SwiftUI
import UIKit

var registry = RichTextTokenViewRegistry()

// 更推荐：用 registerTyped(...) 直接拿到强类型 payload
struct MentionPayload: Codable, Sendable { let name: String }
struct TopicPayload: Codable, Sendable { let name: String }

registry.registerTyped(type: "mention") { (_: RichTextItem, payload: MentionPayload, _: UIFont) in
    RichTextTokenView(Text(payload.name))
}
registry.registerTyped(type: "topic") { (_: RichTextItem, payload: TopicPayload, _: UIFont) in
    RichTextTokenView(Text(payload.name))
}
```

### 4) 使用 RichTextEditorView

```swift
import UIComponentKit
import SwiftUI

@StateObject var vm = RichTextEditorViewModel(configuration: config, editorConfig: editorStyle)
@State var insertString: String? = nil
@State var isEditing: Bool = false

var body: some View {
    RichTextEditorView(
        viewModel: vm,
        isEditing: $isEditing,
        insertString: $insertString,
        tokenViewRegistry: tokenViewRegistry
    )
}
```

只读展示（不可编辑）：

```swift
import UIComponentKit
import SwiftUI

let vm = RichTextEditorViewModel(configuration: config, editorConfig: editorStyle)
vm.isEditable = false
vm.setContent(content) // RichTextContent（来自服务端/草稿/placeholder decode）

var body: some View {
    RichTextEditorView(
        viewModel: vm,
        tokenViewRegistry: tokenViewRegistry
    )
}
```

- 只读模式不需要传 `isEditing/insertString`，也不会走 trigger/keyword 组合态逻辑。
- token 仍然可点：优先走 `RichTextTokenConfig.onTap`，否则走 `editorConfig.onTokenTap`。

### 5) 外部插入与联动

插入纯文本（常见：点按钮插个 `@`）：

```swift
insertString = "@"
```

插入 token（常见：选中候选后插入）：

```swift
RichTextEditorView(
    viewModel: vm,
    tokenViewRegistry: tokenViewRegistry
)

vm.insertTokenAtCursor(item: suggestion, trigger: MentionTrigger())
```

`insertToken` 与 `insertTokenAtCursor` 区别：
- `insertToken(item:trigger:)`：从 `viewModel.getTriggerLocation()` 替换到当前光标（组合态插入）。
- `insertTokenAtCursor(item:trigger:)`：在当前光标/选区插入（外部面板/按钮插入）。


### 接入示例（LoreEntry/Publish）
- 参考 `Business/LoreEntry/Sources/LoreEntryServiceImpl.swift`（`_LoreEntryRichTextKitEditor`）。
- 关键点：注册 `MentionTrigger`、`RichTextTokenConfig.typed`、`RichTextTokenViewRegistry.typed`，用 `vm.searchKeyword/activeTrigger` 驱动面板。

## 核心模型与概念

先记住这三类东西就够用：
| 名称 | 你关心什么 | 用在哪 |
| --- | --- | --- |
| `RichTextItem` | token 的“结构化描述”（type/id/displayText/payload） | 序列化、解析、点击回调 |
| `RichTextTokenConfig` | 候选如何变成 item/payload + token 点击处理 | `registerToken(type:config:)` |
| `RichTextTokenViewRegistry` | item/payload 如何渲染成 SwiftUI token view | `RichTextEditorView(tokenViewRegistry:)` |

### RichTextItem
- `type`：`text` / `mention` / `topic` / 业务自定义类型
- `displayText`：展示文本（token 通常包含 `@` 或 `#...#`）
- `data`：业务主键（推荐只放 id）
- `payload`：业务扩展数据（JSON 字符串；推荐 `Codable`）

### RichTextContent
- `items: [RichTextItem]`
- `plainText`：简单拼接 `displayText`（仅用于展示/统计）

## 类型流转（dataBuilder -> viewBuilder）
- `RichTextTokenConfig.typed<Suggestion, Payload>`：`Suggestion` 通常通过闭包参数显式标注让编译器推断；内部会把 `any SuggestionItem` 做一次运行时 `as? Suggestion` 转换，类型不匹配会触发断言并降级为纯文本（避免线上崩溃）。
- `dataBuilder` 返回 `(item, payload)` 后，`payload` 会被 `JSONEncoder` 编码进 `item.payload`。
- `RichTextTokenViewRegistry.typed<Payload>` 在渲染时用 `Payload.self` 解码 `item.payload`，成功后才进入 `viewBuilder`。
- `type + Payload` 与 encoder/decoder 必须在 config 与 registry 两端保持一致，否则会解码失败导致不渲染或点击回调不触发。

## 内容序列化与兼容

### 1) RichTextContent 的持久化
- `RichTextContent/RichTextItem` 均为 `Codable`：可直接 `JSONEncoder/Decoder` 存储草稿或与服务端交互。
- `plainText` 仅用于展示/统计，不可作为恢复富文本的依据。

### 2) payload 缺失的回填
当服务端只回 `type + data(id) + displayText`，但 token 渲染需要更多字段：

```swift
let fixed = content.backfillPayload(
    forType: "mention",
    payloadByData: [
        "userId1": YourMentionPayload(id: "userId1", name: "Alice", avatar: "...")
    ]
)
vm.setContent(fixed)
```

对应实现：`Base/UIComponentKit/Sources/UIComponentKit/RichTextKit/Models/RichTextContent+PayloadBackfill.swift`。

### 3) 兼容旧协议：@{user_xxx} / @{concept_xxx}
`MentionTrigger` 提供 placeholder codec：
- `MentionTrigger.makePlaceholder(kind:id:)`：生成 `@{user_<id>}` / `@{concept_<id>}`。
- `MentionTrigger.decodePlaceholders(description:resolveName:)`：把占位符字符串解析为 `RichTextContent`。

```swift
let content = MentionTrigger.decodePlaceholders(description: text) { kind, id in
    lookupName(kind: kind, id: id)
}
vm.setContent(content)
```

## 架构与实现（维护者）

### 关键文件
- `Base/UIComponentKit/Sources/UIComponentKit/RichTextKit/Views/RichTextEditorView.swift`
- `Base/UIComponentKit/Sources/UIComponentKit/RichTextKit/ViewModel/RichTextEditorViewModel.swift`
- `Base/UIComponentKit/Sources/UIComponentKit/RichTextKit/Rendering/RichTextAttributedTextRenderer.swift`
- `Base/UIComponentKit/Sources/UIComponentKit/RichTextKit/Views/RichTextTokenViewRegistry.swift`
- `Base/UIComponentKit/Sources/UIComponentKit/RichTextKit/Configuration/RichTextConfiguration.swift`
- `Base/UIComponentKit/Sources/UIComponentKit/RichTextKit/Configuration/RichTextTokenConfig.swift`

### SwiftUI/YYText 封装
- `YYTextEditorRepresentable` 创建并更新 `YYTextView`，把 SwiftUI 状态桥接给 coordinator。
- 关键能力：`textHighlight`（点击）、`YYTextAttachment`（token 视图）、富文本 attributes（自定义 metadata）。
- 渲染链路：renderer 把 `RichTextContent` 转为 `NSAttributedString`，为 token 插入 attachment + highlight + 元信息 attributes。
- 编辑态点击兜底：highlight 命中不稳定时走 tap gesture，通过 attributes 反查 token 元信息并回调 ViewModel。

### Coordinator：RichTextEditorCoordinator（YYTextViewDelegate）
- 输入拦截：`shouldChangeTextIn` -> `evaluateInputChange`（range 钳制、字符限制、调用 VM.shouldChangeText）。
- 解析回写：`textViewDidChange` -> `viewModel.textDidChange`。
- 程序化插入：`insertPlainText` / `insertToken` / `insertTokenAtCursor`。
- 滚动稳定：插入或外部 `setContent` 后 `scrollRangeToVisible(selectedRange)`。

### ViewModel：RichTextEditorViewModel
- 状态：`content`、`activeTrigger`、`searchKeyword`、`isEditable`。
- 组合态：`shouldChangeText` 更新 `activeTrigger/searchKeyword`，外部直接监听这两个 Published 值驱动面板。
- 外部 `setContent`：发布 `pendingContent`，由 coordinator 渲染并回写解析。
- token 点击分发：优先走 `tokenConfig.onTap`，否则回退到全局 `onTokenTap`。

### Renderer：RichTextAttributedTextRenderer
- `render(content, configuration, editorConfig, tokenViewRegistry)` 生成 `NSAttributedString`。
- token 处理：attachment + highlight + metadata attributes。

### Configuration/Trigger
- `RichTextConfiguration` 维护 trigger 与 tokenConfig（数据构建 + 点击回调）。
- `MentionTrigger` / `TopicTrigger` 实现 `RichTextTrigger`，定义 triggerCharacter/tokenType/tokenFormat/tokenColor。
