# Adapters 模块

## 职责
提供具体输入组件的桥接适配器实现。

## 核心组件

### RichTextInputBridgeAdapter
RichTextKit 的适配器实现：
- 实现 `KeyboardPanelTokenInputBridge` 协议
- 桥接 `RichTextEditorViewModel` 与 KeyboardPanelKit
- 支持 Token 插入（@提及、#话题# 等）
- 支持 Trigger 监听（输入 @ 或 # 时触发）

## 使用方式

```swift
let richTextVM = RichTextEditorViewModel()
let adapter = RichTextInputBridgeAdapter(viewModel: richTextVM)

adapter.onTriggerChanged = { trigger, keyword in
    if trigger != nil {
        panelVM.showPanel("mention")
    }
}

adapter.onContentChanged = { text in
    // 更新外部 UI
}
```

## 扩展

业务层可以实现自己的适配器来适配其他输入组件：

```swift
class MyTextFieldAdapter: KeyboardPanelInputBridge {
    // 实现协议方法
}
```
