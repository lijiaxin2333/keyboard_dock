# Demo 模块

## 职责
提供 KeyboardPanelKit 的使用示例。

## 示例视图

### KeyboardPanelDemoView
使用便捷 API（KeyboardPanel）的示例：
- 预设工具栏布局
- 表情面板、更多面板
- 快捷表情栏

### CustomToolbarDemoView
使用 KeyboardPanelContainer 完全自定义的示例：
- 自定义工具栏布局
- 使用 KeyboardPanelContext 控制状态
- 展示如何实现业务解耦

## 业务组件

### EmojiPanelView
表情面板示例：
- 分类选择栏
- 最近使用表情
- 表情网格

## 使用方式
```swift
// 便捷 API
KeyboardPanelDemoView()

// 完全自定义
CustomToolbarDemoView()
```
