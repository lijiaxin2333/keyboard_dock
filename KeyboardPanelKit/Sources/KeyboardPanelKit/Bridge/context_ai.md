# Bridge 模块

## 职责
定义输入桥接协议，实现框架与具体输入组件的解耦。

## 核心组件

### KeyboardPanelInputBridge
基础输入桥接协议：
- `plainText`: 获取纯文本
- `isEmpty`: 是否为空
- `insertText(_:)`: 插入文本
- `clearContent()`: 清空内容
- `onContentChanged`: 内容变化回调

### KeyboardPanelTokenInputBridge
支持 Token 的输入桥接协议（继承自 KeyboardPanelInputBridge）：
- `insertToken(_:trigger:)`: 插入 Token
- `activeTrigger`: 当前激活的触发器
- `searchKeyword`: 搜索关键词
- `onTriggerChanged`: 触发器变化回调

### SimpleTextInputBridge
简单文本输入桥接实现，适用于普通 TextField。

## 使用方式

业务层实现协议来适配具体输入组件：

```swift
// RichTextKit 适配器示例
class RichTextInputBridgeAdapter: KeyboardPanelTokenInputBridge {
    typealias TokenItem = any SuggestionItem
    typealias TriggerType = RichTextTrigger
    
    let viewModel: RichTextEditorViewModel
    // ...
}
```

## 依赖关系
- 不依赖任何具体输入实现
- 由外部适配器实现协议
