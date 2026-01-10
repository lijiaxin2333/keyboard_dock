# Panel 模块

## 职责
定义面板相关的数据模型。

## 核心组件

### KeyboardPanelItem
面板项定义，包含：
- id: 唯一标识
- icon: 图标
- selectedIcon: 选中时的图标（如表情面板显示键盘图标）
- title: 标题（可选）

预定义面板项：
- at: @提及
- emoji: 表情
- photo: 图片
- voice: 语音
- more: 更多功能

### KeyboardPanelState
面板状态枚举：
- keyboard: 显示键盘
- panel: 显示指定面板
- none: 无显示

## 使用方式
工具栏按钮对应 KeyboardPanelItem，点击时切换 KeyboardPanelState。
