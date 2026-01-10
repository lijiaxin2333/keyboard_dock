# Core 模块

## 职责
提供全局配置、主题定义和上下文传递。

## 核心组件

### KeyboardPanelContext
传递给外部注入视图的上下文对象：
- 状态信息：panelState, keyboardHeight, isTransitioning
- 操作方法：showPanel, showKeyboard, requestShowKeyboard, dismiss
- 便捷属性：currentPanelId, isKeyboardVisible, isPanelVisible

### KeyboardPanelColors
颜色主题配置，包含：
- 工具栏背景色
- 面板背景色
- 输入框背景色/文字色/占位符色
- 按钮色调
- 发送按钮背景/前景色
- 分割线颜色

### KeyboardPanelAccessoryConfiguration
预设工具栏配置（用于便捷 API）：
- 占位符文字
- 发送按钮标题
- 颜色主题
- 各种尺寸参数

## 使用方式
KeyboardPanelContext 通过闭包参数传递给外部视图，也可通过 Environment 访问。
