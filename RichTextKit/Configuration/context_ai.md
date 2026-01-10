# Configuration

作用
- 管理触发器与 token 配置：注册/查询触发符号，绑定 token 数据构建与点击回调。
- 定义编辑器 UI 与限制（RichTextEditorStyle）：占位符、字体、颜色、最大高度、字符上限、键盘外观、全局 token 点击回调。

核心能力/原理
- RichTextConfiguration：`register(_:)` 以 triggerCharacter 作为键；`trigger(for:)` 单字符匹配；`registerToken(type:config:)` 建立 type -> RichTextTokenConfig。
- RichTextTokenConfig：`dataBuilder(SuggestionItem)` 生成 `(RichTextItem,payload)`，payload 会 JSON 编码进 `item.payload`；`onTap` 优先级高于 EditorConfig 的 `onTokenTap`。
- RichTextEditorStyle：纯 UI 配置，已无 suggestionEvent；组合态信号依赖 ViewModel 的 Published 状态。

使用方式
```swift
let config = RichTextConfiguration()
config.register(MentionTrigger(tokenColor: .systemBlue))
config.register(TopicTrigger(tokenColor: .systemOrange))
config.registerToken(type: "mention", config: RichTextTokenConfig.typed(dataBuilder: { s in ... }, onTap: { item, payload in ... }))

let editorStyle = RichTextEditorStyle(placeholder: "请输入内容", font: .systemFont(ofSize: 16), textColor: .label, maxHeight: 200, characterLimit: .init(maxCount: 500, onExceeded: { _ in ... }), onTokenTap: { item in ... })
```

---

## iOS/Android 设计差异

### 展开/收起功能（Expand/Collapse）

#### iOS 当前设计（方案 B）

**核心设计：** 使用两个独立类型 `_expand` 和 `_collapse`

```swift
// 注册展开按钮
config.registerToken(
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

// 注册收起按钮
config.registerToken(
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
```

**实现方式：**
- 每个类型绑定固定行为（expand = true, collapse = false）
- 根据状态动态插入不同类型的 token
- 点击行为通过 `onTap` 回调直接设置状态

**优势：**
- ✅ 简单直观，每个类型对应一个明确的行为
- ✅ 低耦合，不需要额外的状态管理
- ✅ 动态性强，可根据状态插入不同 token

**劣势：**
- ❌ 类型不安全（使用字符串，容易拼写错误）
- ❌ 重复注册（需要注册两个几乎相同的配置）
- ❌ 行为分散（点击行为定义在 config 里，而不是统一处理）

#### Android 设计（方案 A - 推荐）

**核心设计：** 使用单一类型 `ExpandToggleMark` + `Mode` 枚举

```kotlin
// 展开标记（内部使用，不参与序列化）
data class ExpandToggleMark(
    val mode: Mode,  // 枚举类型，编译期检查
    override val displayText: String,
    val style: SpanStyle? = null,
    override val range: IntRange = 0..0
) : RichMark.Custom(range) {
    enum class Mode { Expand, Collapse }
    override fun withRange(newRange: IntRange): ExpandToggleMark = copy(range = newRange)
}

// 配置类
data class CollapseConfig(
    val collapsedMaxHeight: Dp? = null,
    val collapsedMaxLines: Int? = null,
    val collapsedMaxCharacters: Int? = null,
    val expandText: String = "展开",
    val collapseText: String = " 收起",
    val toggleStyle: SpanStyle? = null,
    val initialExpanded: Boolean = false
)
```

**状态管理：** ViewModel 作为 Single Source of Truth
```kotlin
class RichTextEditorViewModel {
    var collapseConfig: CollapseConfig? = null  // 业务配置
    val isExpandedFlow: StateFlow<Boolean>       // 状态流
    fun setExpanded(expanded: Boolean)          // 公开方法
}

// 事件流
sealed interface RichTextEditorEffect {
    data class ExpandStateChanged(val isExpanded: Boolean) : RichTextEditorEffect
}
```

**实现方式：**
- 收起态：截断文本 + `ExpandToggleMark(Mode.Expand, expandText)`
- 展开态：完整文本 + `ExpandToggleMark(Mode.Collapse, collapseText)`
- 点击处理：拦截 `ExpandToggleMark` 点击，切换状态
- 状态变化：通过 `effectFlow` 发送 `ExpandStateChanged` 事件

**优势：**
- ✅ 类型安全（枚举，编译期检查）
- ✅ 单一配置类管理所有逻辑
- ✅ 状态集中在 ViewModel，符合 MVVM
- ✅ 代码简洁，无重复配置
- ✅ 易于扩展（未来可添加新 Mode）

**劣势：**
- ⚠️ 稍复杂，需要根据 mode 判断行为
- ⚠️ 依赖 ViewModel，点击处理需要访问状态

#### 对比总结

| 维度 | iOS（方案 B） | Android（方案 A） | 推荐方案 |
|------|---------------|-------------------|----------|
| **类型数量** | 2 个字符串类型 | 1 个类 + 枚举 | ✅ Android |
| **类型安全** | ❌ 字符串（易拼写错误） | ✅ 枚举（编译期检查） | ✅ Android |
| **配置数量** | ❌ 需要注册两次 | ✅ 一个配置 | ✅ Android |
| **状态管理** | 分散在 token 配置 | 集中在 ViewModel | ✅ Android |
| **代码重复** | ❌ 高（两个配置） | ✅ 低（一个配置） | ✅ Android |
| **扩展性** | 需要新增类型 | 扩展枚举即可 | ✅ Android |
| **简单直观** | ✅ 每个类型对应明确行为 | ✅ 状态逻辑清晰 | 平手 |

#### 对齐建议

**当前状态：** 双端实现都已完成，功能对齐，但设计思路不同。

**推荐方案：** Android 的方案 A（单一类型 + 枚举）更优。

**未来改造建议：** iOS 可以参考 Android 的设计，改为单一类型 + 枚举：

```swift
enum ExpandToggleMode: String {
    case expand
    case collapse
}

config.registerToken(
    type: "_toggle",
    config: RichTextTokenConfig(
        dataBuilder: { [expandText, collapseText] item in
            let isExpanded = item.data == "collapse"
            return RichTextItem(
                type: "_toggle",
                displayText: isExpanded ? collapseText : expandText,
                data: isExpanded ? "collapse" : "expand"
            )
        },
        onTap: { [state] item in
            Task { @MainActor in
                state.isExpanded = (item.data == "expand")
            }
        }
    )
)
```

**对齐记录：**
- ✅ Android 保持当前设计（方案 A）
- 📝 iOS 记录此设计差异，未来改造时参考
- 📄 双端 `context_ai.md` 都记录此设计差异
