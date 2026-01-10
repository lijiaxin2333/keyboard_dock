# Demo 模块

## 职责
提供 KeyboardPanelKit 的示例用法。

## 核心组件

### EmojiPanelView
表情面板视图，包含：
- 分类选择栏
- 最近使用表情
- 表情网格

### KeyboardPanelDemoView
完整示例视图，展示：
- 消息列表
- 键盘工具栏
- 表情面板切换
- 快捷表情栏
- 更多功能面板

## 使用方式
```swift
struct ContentView: View {
    var body: some View {
        KeyboardPanelDemoView()
    }
}
```
