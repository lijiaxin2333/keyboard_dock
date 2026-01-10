# Panel 模块

## 职责
定义面板状态枚举。

## 核心组件

### KeyboardPanelState
面板状态枚举：
- `keyboard`: 显示键盘
- `panel(String)`: 显示指定 ID 的面板
- `none`: 无显示

便捷属性：
- `isKeyboard`: 是否为键盘状态
- `isPanel`: 是否为面板状态
- `currentPanelId`: 当前面板 ID（仅在 panel 状态下有值）

## 使用方式

```swift
switch context.panelState {
case .keyboard:
    // 键盘显示中
case .panel(let panelId):
    // 显示 panelId 对应的面板
case .none:
    // 无显示
}
```

## 注意
- `KeyboardPanelItem` struct 已移至 Demo/Presets，不再是框架核心
- 框架层只使用 String 作为面板标识
