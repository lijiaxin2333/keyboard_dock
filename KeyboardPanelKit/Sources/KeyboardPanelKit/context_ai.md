# KeyboardPanelKit

## 概述
纯 SwiftUI 实现的键盘面板管理框架，完全解耦 UI 层，支持外部注入任意视图和适配任意输入组件。

## 架构设计

```
框架层（不依赖任何 UI/输入实现）
├── KeyboardPanelContainer    - 纯布局容器
├── KeyboardPanelViewModel    - 状态管理
├── KeyboardPanelContext      - 上下文传递
├── KeyboardPanelConfiguration - 配置项
├── KeyboardPanelState        - 状态枚举
├── Bridge/                   - 输入桥接协议
└── Keyboard/                 - 键盘事件监听

Demo 层（可选的预设实现）
├── Presets/                  - 样式配置、预设组件
├── Adapters/                 - 输入适配器
└── Components/               - 业务组件
```

## 核心组件

### KeyboardPanelContainer
纯布局容器，接受外部注入的视图：
- `accessoryView`: 工具栏区域（完全自定义）
- `panelView`: 面板内容（根据 panelId 返回）
- `contextBuilder`: 扩展 Context（添加 insertText 等）

### KeyboardPanelContext
传递给外部视图的上下文：
- 状态：panelState, keyboardHeight, isTransitioning
- 操作：showPanel, showKeyboard, requestShowKeyboard, dismiss
- 输入：insertText, clearContent（通过 contextBuilder 绑定）
- 扩展：userInfo（自定义数据）

### KeyboardPanelInputBridge
输入桥接协议，支持适配任意输入组件：
- `KeyboardPanelInputBridge`: 基础协议
- `KeyboardPanelTokenInputBridge`: 支持 Token 的协议

## 使用方式

```swift
KeyboardPanelContainer(
    viewModel: viewModel,
    contextBuilder: { context in
        var ctx = context
        ctx.insertText = { adapter.insertText($0) }
        return ctx
    },
    accessoryView: { context in
        // 完全自定义工具栏
    },
    panelView: { context, panelId in
        // 根据 panelId 返回面板
    }
)
```

## 依赖关系

- 框架层不依赖任何 UI/输入实现
- 通过协议抽象支持任意输入组件
- Demo 层提供可选的预设实现
