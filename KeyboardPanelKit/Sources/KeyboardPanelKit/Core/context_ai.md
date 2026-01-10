# Core 模块

## 职责
提供框架核心配置和上下文传递。

## 核心组件

### KeyboardPanelConfiguration
框架配置项：
- `animationDuration`: 动画时长（默认 0.25）
- `defaultKeyboardHeight`: 默认键盘高度（默认 336）

### KeyboardPanelContext
传递给外部视图的上下文：

状态信息：
- `panelState`: 当前面板状态
- `keyboardHeight`: 键盘高度
- `panelDisplayHeight`: 面板显示高度
- `isTransitioning`: 是否正在过渡
- `bottomSafeAreaHeight`: 底部安全区高度

操作方法：
- `showPanel(id:)`: 显示指定面板
- `showKeyboard()`: 显示键盘
- `requestShowKeyboard()`: 请求切回键盘（有过渡动画）
- `dismiss()`: 收起所有

输入操作（通过 contextBuilder 绑定）：
- `insertText`: 插入文本
- `clearContent`: 清空内容

自定义数据：
- `userInfo`: 业务层自定义数据字典

便捷属性：
- `currentPanelId`: 当前面板 ID
- `isKeyboardVisible`: 键盘是否可见
- `isPanelVisible`: 面板是否可见

## 使用方式

```swift
KeyboardPanelContainer(
    viewModel: viewModel,
    contextBuilder: { context in
        var ctx = context
        ctx.insertText = { adapter.insertText($0) }
        ctx.userInfo["myData"] = someValue
        return ctx
    },
    accessoryView: { context in
        // 使用 context 中的状态和方法
    }
)
```
