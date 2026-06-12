# MultipleCapsuleButton 设计方案

## 目标

当前项目已有 `MorphingCapsuleButton`，适合少量选项的分段胶囊，例如 `1:1 / 4:3 / 16:9`。

当选项数量变多，例如 6 个或更多时，继续使用普通分段胶囊会导致每个选项空间过窄。因此新增一个通用组件：`MultipleCapsuleButton`。

它的核心目标是：

- 多选项时仍然保持原地形变展开。
- 展开锚点逻辑与 `MorphingCapsuleButton` 完全一致。
- 选项数量较多时支持横向滑动。
- 未选项越靠近左右边缘越淡，但文字不能被硬裁切。
- 点击某个选项后更新选中项，并沿用当前 `0.2s` 后收回的闭环。

## 自动选择规则

组件类型不在数据里手动指定，而是根据选项数量自动决定：

```swift
options.count <= 3  -> MorphingCapsuleButton
options.count > 3   -> MultipleCapsuleButton
```

这样数据层只表达“这是一个选项型 item”，展示层根据数据规模选择合适 UI。

## 架构分层

### 1. `CameraSettingsSheet`

父容器只负责：

- 维护 `expandedItemID`。
- 维护每个 item 的选中值，例如 `optionSelections[item.id]`。
- 维护 Bottom Sheet 的显示/隐藏生命周期。
- 渲染多行不等列布局。
- 根据 item 的选项数量选择 `MorphingCapsuleButton` 或 `MultipleCapsuleButton`。

父容器不应该关心某个胶囊内部怎么排布选项。

### 2. `SettingItem`

数据模型继续表达 item 的稳定信息：

```swift
struct SettingItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let kind: SettingItemKind
    let position: ButtonPosition
}
```

如果后续所有 item 都要像“比例”一样展开，则它们都应该是：

```swift
.options(["1:1", "4:3", "16:9"])
```

如果某个 item 需要多选项，则可以是：

```swift
.options(["2:1", "1:1", "4:3", "16:9", "2.35:1", "3:2"])
```

### 3. `ButtonPosition`

锚点逻辑继续复用当前设计：

```swift
enum ButtonPosition {
    case left, center, right

    var anchor: Alignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
}
```

这套逻辑必须同时服务两个组件：

- `MorphingCapsuleButton`
- `MultipleCapsuleButton`

不要在 `MultipleCapsuleButton` 里重新写一套方向判断。

## 宽度设计原则

这是最重要的约束：**不能直接写死宽度。**

禁止出现类似：

```swift
.frame(width: 320)
.frame(width: 145)
.frame(width: 72)
```

所有横向尺寸都必须从当前布局推导出来。

允许使用设计 token：

- 高度，例如按钮高度 `60`。
- 圆角，例如 `20`。
- 间距，例如行内 spacing `12`。
- 内边距，例如水平 padding。

但宽度必须来自：

- 屏幕宽度。
- 当前网格 cell 的 `slotWidth`。
- 当前行的 item 数量。
- 当前展开胶囊的可用宽度。

## 宽度推导方式

每个按钮依然通过 `GeometryReader` 获取当前格子的宽度：

```swift
GeometryReader { geo in
    let slotWidth = geo.size.width
}
```

收起状态宽度：

```swift
collapsedWidth = slotWidth
```

展开状态宽度：

```swift
expandedWidth = slotWidth * CGFloat(rowItemCount)
    + rowSpacing * CGFloat(rowItemCount - 1)
```

这样展开后的胶囊宽度永远等于当前行的整行宽度，不依赖固定数值，也不会因为设备宽度变化而错位。

锚点仍然由 `ButtonPosition` 决定：

```swift
.frame(
    width: slotWidth,
    height: buttonHeight,
    alignment: item.position.anchor
)
```

实际形变体内部使用：

```swift
.frame(
    width: isExpanded ? expandedWidth : slotWidth,
    height: buttonHeight
)
```

因此：

- 左侧 item：向右展开。
- 右侧 item：向左展开。
- 居中 item：向左右两侧对称展开。

## `MultipleCapsuleButton` 的 UI 结构

展开后结构如下：

```text
MultipleCapsuleButton
  GeometryReader
    outer capsule background
    horizontal options area
      option item
      option item
      selected option highlight
      option item
      option item
```

视觉效果：

- 外层是深色毛玻璃/半透明胶囊。
- 中间选中项显示荧光黄绿色高亮块。
- 未选项文字为白色。
- 左右越靠近边缘，透明度越低。
- 透明度变化通过每个 option 的位置计算，不优先使用会硬切文字的 mask。

## 多选项滑动逻辑

当 `options.count > 3` 时，内部应该支持横向滑动。

推荐实现方式：

- 外层胶囊宽度固定为 `expandedWidth`。
- 内部使用横向滚动区域或自定义拖拽位移。
- 每个 option 的宽度根据 `expandedWidth` 推导，而不是写死。
- 当前选中项默认滚动到靠近中心的位置。
- 用户可以左右滑动查看更多选项。

选项 cell 宽度可以从展开宽度推导，例如：

```swift
optionCellWidth = expandedWidth / visibleOptionCount
```

其中 `visibleOptionCount` 是设计比例，不是绝对宽度。它可以决定一屏大约展示多少个选项，但最终宽度仍然来自 `expandedWidth`。

## 边缘渐淡逻辑

不要通过把文字裁掉来制造“淡出”。

推荐方式是根据每个 option 中心点和胶囊中心点的距离计算透明度：

```text
越靠近中心 -> opacity 越高
越靠近左右边缘 -> opacity 越低
```

概念公式：

```swift
let distance = abs(optionCenterX - capsuleCenterX)
let progress = distance / (expandedWidth / 2)
let opacity = 1 - progress * fadeStrength
```

最终 clamp 到一个最小透明度，例如：

```swift
opacity = max(minOpacity, opacity)
```

这样边缘选项是“变淡”，不是“被硬裁切”。

## 交互闭环

`MultipleCapsuleButton` 和当前 `MorphingCapsuleButton` 保持一致：

1. 点击收起状态按钮。
2. 父级设置 `expandedItemID = item.id`。
3. 胶囊按锚点展开。
4. 点击某个 option。
5. 更新 `optionSelections[item.id]`。
6. 延迟 `0.2s`。
7. 设置 `expandedItemID = nil`，胶囊原路收回。

这部分逻辑仍然放在父级的 `select(_:for:)` 中，子组件只通过 `onSelect(option)` 回调通知父级。

## 层级与互斥

两个胶囊组件都必须遵守同一套规则：

- 展开状态 `zIndex = 10`。
- 非展开状态 `zIndex = 0`。
- 同一时间只允许一个 item 展开。
- 展开的 item 覆盖同一行兄弟 item。
- 点击面板空白区域收回当前展开项。

父级继续使用：

```swift
@State private var expandedItemID: String?
```

子组件只接收：

```swift
let isExpanded: Bool
```

## 后续实现建议

建议新增文件：

```text
MultipleCapsuleButton.swift
```

保留现有：

```text
MorphingCapsuleButton.swift
```

如果后续发现两个组件重复代码很多，可以再抽一个共享布局 helper，例如：

```swift
func expandedWidth(slotWidth: CGFloat, rowItemCount: Int, rowSpacing: CGFloat) -> CGFloat
```

但第一版不建议过早抽象。先保证两个组件各自清晰、稳定，再提取公共逻辑。

## 实现底线

- 不写死任何横向宽度。
- 不因为数据多而把外层胶囊无限撑宽。
- 不让展开动画挤压兄弟按钮。
- 不重新实现一套锚点判断。
- 不把选中状态放在子组件内部。
- 不让多选项文字被硬裁切。
- 不破坏当前 `0.2s` 选择后收回的交互闭环。
