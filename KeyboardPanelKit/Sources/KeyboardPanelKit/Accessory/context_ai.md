# Accessory 模块

## 职责
提供键盘工具栏视图组件。

## 核心组件

### KeyboardAccessoryView
主工具栏视图，包含：
- 输入框：支持多行输入
- 功能按钮区：横向排列的面板切换按钮
- 发送按钮

功能：
- 点击功能按钮触发面板切换回调
- 根据当前面板状态显示不同图标
- 支持自定义配置

### KeyboardAccessoryQuickBar
快捷内容栏，用于显示表情快捷选择等内容。

## 使用方式
```swift
KeyboardAccessoryView(
    text: $text,
    isInputFocused: $isInputFocused,
    panelItems: [.emoji, .photo, .more],
    currentPanelState: viewModel.panelState,
    onPanelItemTap: { item in
        viewModel.togglePanel(item)
    },
    onSend: {
        // 发送消息
    }
)
```
