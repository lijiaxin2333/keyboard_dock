# Demo 模块

## 职责
提供 KeyboardPanelKit 的使用示例和预设组件。

## 目录结构

```
Demo/
├── Presets/           # 预设组件（样式配置、工具栏等）
│   ├── KeyboardPanelItem.swift
│   ├── KeyboardPanelColors.swift
│   ├── KeyboardPanelAccessoryConfiguration.swift
│   └── KeyboardAccessoryView.swift
├── Adapters/          # 输入适配器
│   └── RichTextInputBridgeAdapter.swift
├── Components/        # 业务组件
│   └── EmojiPanelView.swift
└── KeyboardPanelDemoView.swift  # 示例视图
```

## Presets - 预设组件

### KeyboardPanelItem
面板项定义，包含图标和选中状态图标。

### KeyboardPanelColors
颜色主题配置，提供 default 和 dark 两套预设。

### KeyboardPanelAccessoryConfiguration
工具栏配置，包含占位符、发送按钮标题、尺寸等。

### KeyboardAccessoryView
预设工具栏视图，可直接使用。

## Adapters - 输入适配器

### RichTextInputBridgeAdapter
RichTextKit 的适配器，实现 KeyboardPanelTokenInputBridge 协议。

## Components - 业务组件

### EmojiPanelView
表情面板视图，包含分类和表情网格。

## 使用示例

```swift
// 使用框架核心 + 预设组件
KeyboardPanelContainer(
    viewModel: viewModel,
    contextBuilder: { context in
        var ctx = context
        ctx.insertText = { text += $0 }
        return ctx
    },
    accessoryView: { context in
        // 使用预设或完全自定义
        MyCustomToolbar(context: context)
    },
    panelView: { context, panelId in
        // 根据 panelId 返回面板
        EmojiPanelView(onEmojiSelect: { context.insertText?($0) })
    }
)
```
