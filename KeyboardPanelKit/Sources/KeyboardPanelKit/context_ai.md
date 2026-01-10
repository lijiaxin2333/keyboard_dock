# KeyboardPanelKit

## 概述
纯 SwiftUI 实现的键盘面板管理框架，支持完全自定义工具栏和面板内容，实现业务与基础能力解耦。

## 模块结构

```
KeyboardPanelKit/
├── Keyboard/           # 键盘事件监听和焦点控制
├── Core/               # 配置项、颜色主题、上下文
├── Panel/              # 面板状态模型
├── Accessory/          # 预设工具栏组件（可选）
├── Demo/               # 使用示例
├── KeyboardPanelContainer.swift  # 纯框架容器（推荐）
├── KeyboardPanelViewModel.swift  # 状态管理
└── KeyboardPanel.swift           # 便捷 API（预设布局）
```

## 核心组件

### KeyboardPanelContainer（推荐）
完全泛型化的容器，支持外部注入所有视图：

```swift
KeyboardPanelContainer(
    viewModel: viewModel,
    accessoryView: { context in
        // 完全自定义工具栏
    },
    quickBarView: { context in
        // 完全自定义快捷栏
    },
    panelView: { context, panelId in
        // 根据 panelId 返回面板内容
    }
)
```

### KeyboardPanelContext
传递给子视图的上下文对象：
- `panelState`: 当前状态
- `keyboardHeight`: 键盘高度
- `panelDisplayHeight`: 面板显示高度
- `isTransitioning`: 是否过渡中
- `showPanel(id:)`: 显示面板
- `showKeyboard()`: 显示键盘
- `requestShowKeyboard()`: 请求切回键盘（有过渡）
- `dismiss()`: 收起所有

### KeyboardPanel（便捷 API）
预设布局的便捷封装，适合快速集成：

```swift
KeyboardPanel(
    viewModel: viewModel,
    text: $text,
    panelItems: [.emoji, .photo, .more],
    onSend: { },
    panelContent: { item in ... },
    quickBarContent: { ... }
)
```

## 依赖关系

- Keyboard 模块通过 Factory 提供实现
- 各模块通过协议解耦
- 遵循 MVVM 架构
- 业务代码通过 ViewBuilder 注入
