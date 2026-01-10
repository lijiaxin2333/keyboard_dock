# KeyboardPanelKit

## 概述
纯 SwiftUI 实现的键盘面板管理框架，用于实现类似微信/iMessage 的输入体验。

## 模块结构

```
KeyboardPanelKit/
├── Keyboard/           # 键盘事件监听和焦点控制
├── Core/               # 配置项和颜色主题
├── Panel/              # 面板数据模型
├── Accessory/          # 工具栏视图
├── KeyboardPanelViewModel.swift  # 状态管理
└── KeyboardPanel.swift           # 主视图
```

## 使用方式

```swift
struct ContentView: View {
    @StateObject private var viewModel = KeyboardPanelViewModel()
    @State private var text = ""
    
    var body: some View {
        VStack {
            // 聊天内容
            Spacer()
            
            KeyboardPanel(
                viewModel: viewModel,
                text: $text,
                panelItems: [.at, .emoji, .photo, .voice, .more],
                onSend: { sendMessage() },
                panelContent: { item in
                    switch item.id {
                    case "emoji":
                        EmojiPanelView()
                    default:
                        EmptyView()
                    }
                },
                quickBarContent: {
                    // 表情快捷栏
                }
            )
        }
    }
}
```

## 核心流程

1. 用户点击输入框 → 键盘弹出 → panelState = .keyboard
2. 用户点击表情按钮 → 键盘收起 + 表情面板弹出 → panelState = .panel(.emoji)
3. 用户再次点击表情按钮（此时显示键盘图标）→ 面板收起 + 键盘弹出 → panelState = .keyboard

## 依赖关系

- Keyboard 模块通过 Factory 提供实现
- 各模块通过协议解耦
- 遵循 MVVM 架构
