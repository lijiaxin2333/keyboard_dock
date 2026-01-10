# Keyboard 模块

## 职责
负责系统键盘事件的监听和焦点控制。

## 核心组件

### KeyboardTypes
- `KeyboardInfo`: 键盘信息结构体，包含高度、动画时长、动画曲线
- `KeyboardState`: 键盘状态枚举 (hidden/showing/shown/hiding)

### KeyboardEventProviding
键盘事件监听协议，提供：
- 键盘状态发布者
- 当前状态
- 最后已知高度

### KeyboardFocusControlling
焦点控制协议，提供：
- 收起键盘
- 激活键盘

### Factory
- `KeyboardEventProviderFactory`: 创建键盘事件提供者
- `KeyboardFocusControllerFactory`: 创建焦点控制器

## 依赖关系
- 依赖 UIKit 进行键盘监听
- 依赖 Combine 进行事件发布
