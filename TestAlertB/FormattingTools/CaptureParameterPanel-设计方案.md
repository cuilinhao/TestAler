# CaptureParameterPanel 设计方案

## 背景

项目二当前已经有顶部 `HEIF` 按钮，并且前一步已经实现了一个简单的 `CaptureFormatPicker`，用于展示 `HEIF / JPEG` 胶囊选择器。

现在需求发生变化：顶部参数弹层不再只是格式选择，而是要承载更完整的相机参数设置 UI。

参考截图中有两个场景：

- 截图 1：拍照/录像参数设置面板，由顶部 `HEIF` 按钮触发。
- 截图 2：倒计时/间隔拍摄设置面板，由 `Timer` 按钮触发。

两个场景的视觉语言一致，只是内容不同。因此不建议继续把组件命名为 `CaptureFormatPicker`，也不建议写两个完全重复的大 View。推荐抽象为一个可复用的顶部参数面板组件。

## 目标

实现一个通用组件：

```swift
CaptureParameterPanel
```

它负责统一渲染截图中的面板样式、参数行布局、选中态、禁用态和 slider 行。

同时提供两个语义清晰的轻量包装视图：

```swift
VideoParameterPanel
TimerParameterPanel
```

其中：

- `VideoParameterPanel` 对应截图 1，由 `HEIF` 按钮触发。
- `TimerParameterPanel` 对应截图 2，由 `Timer` 按钮触发。

所有新增代码建议放在：

```text
TestAlertB/FormattingTools
```

这样后续组件边界清楚，也符合当前项目二的组织要求。

## 需求确认

已确认的交互规则：

- 点击 `HEIF` 按钮：展示截图 1 的参数面板。
- 点击 `Timer` 按钮：展示截图 2 的参数面板。
- 点击面板内某个选项后：面板保持展开，允许继续修改其他参数。
- 绿色预览背景继续保留，不替换成截图里的雪山背景。
- 截图 2 中的“拍摄时长”需要保存真实数值。
- “拍摄时长”的最大值是 `180s`，不是无限。

## 总体设计

### 组件分层

建议采用三层结构：

```text
ContentView / FeaturesToolbar
  负责触发哪个面板

VideoParameterPanel / TimerParameterPanel
  负责组织具体业务数据

CaptureParameterPanel
  负责通用 UI 渲染
```

这样复用的是真正稳定的部分：面板外观、布局、选中样式、禁用样式和 slider 样式。

不同场景只需要换数据，不需要复制 UI 代码。

### 文件建议

可以拆成以下文件：

```text
TestAlertB/FormattingTools/CaptureParameterPanel.swift
TestAlertB/FormattingTools/CaptureParameterModels.swift
TestAlertB/FormattingTools/VideoParameterPanel.swift
TestAlertB/FormattingTools/TimerParameterPanel.swift
```

如果希望文件更少，也可以先合并为：

```text
TestAlertB/FormattingTools/CaptureParameterPanel.swift
```

后续变复杂再拆。

## 状态设计

### 激活面板

父层不要使用多个布尔值，比如：

```swift
@State private var isVideoPanelPresented = false
@State private var isTimerPanelPresented = false
```

这种方式后续扩展会变乱，也容易出现两个面板同时为 `true`。

推荐使用一个枚举：

```swift
enum ActiveParameterPanel {
    case video
    case timer
}
```

父层状态：

```swift
@State private var activeParameterPanel: ActiveParameterPanel?
```

交互规则：

```swift
func togglePanel(_ panel: ActiveParameterPanel) {
    if activeParameterPanel == panel {
        activeParameterPanel = nil
    } else {
        activeParameterPanel = panel
    }
}
```

这样以后新增 `ratio`、`codec`、`resolution` 等面板时，只需要扩展枚举。

### 参数状态

参数选中值建议由父层保存，面板组件只负责显示和回调。

示例：

```swift
@State private var colorSpace = "SDR"
@State private var codec = "ProRes Proxy"
@State private var resolution = "FHD"
@State private var frameRate = "24"

@State private var captureInterval = "1s"
@State private var captureDurationSeconds = 0.0
@State private var timerResolution = "FHD"
```

这样做的好处：

- 面板关闭再打开，选中状态不会丢。
- 后续接入真实相机设置时，只需要把这些状态替换为业务 model 绑定。
- 组件本身保持纯 UI，复用性更好。

## 数据模型

### ParameterOption

每个选项的数据结构：

```swift
struct ParameterOption: Identifiable, Hashable {
    let id: String
    let title: String
    var isEnabled: Bool = true
    var showsLockWhenDisabled: Bool = false
}
```

说明：

- `id` 用于状态保存和比较。
- `title` 用于 UI 展示。
- `isEnabled == false` 时使用灰色禁用样式。
- `showsLockWhenDisabled == true` 时显示锁图标，例如截图 1 的 `120`。

### ParameterRow

面板行支持两种类型：

```swift
enum ParameterRow {
    case options(
        title: String,
        options: [ParameterOption],
        selection: Binding<String>
    )

    case slider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        trailingText: String
    )
}
```

截图 1 全部是 `.options`。

截图 2 包含：

- `.options(title: "拍摄间隔", ...)`
- `.slider(title: "拍摄时长", range: 0...180, trailingText: "180s")`
- `.options(title: "分辨率", ...)`

## UI 设计

### 面板外壳

面板应贴近截图风格：

- 覆盖在绿色预览区域顶部。
- 宽度撑满屏幕。
- 深色半透明背景，带轻微蓝绿色调。
- 底部两个角大圆角。
- 顶部不需要额外标题。
- 不使用卡片阴影。
- 内容区有稳定内边距，避免文字贴边。

建议 token：

```swift
enum CaptureParameterPanelStyle {
    static let backgroundColor = Color(red: 0.01, green: 0.09, blue: 0.11).opacity(0.92)
    static let bottomCornerRadius: CGFloat = 44
    static let horizontalPadding: CGFloat = 38
    static let topPadding: CGFloat = 34
    static let bottomPadding: CGFloat = 34
    static let rowSpacing: CGFloat = 26
    static let titleColumnWidth: CGFloat = 112
    static let optionColumnSpacing: CGFloat = 56
}
```

这些数值可以作为初始值。真正实现时需要根据模拟器截图微调，以尽量贴近用户给的两张图。

### 行布局

每一行由左侧标题和右侧内容组成：

```text
左侧标题         选项 A          选项 B
                选项 C          选项 D
                选项 E
```

选项区建议固定为两列网格：

```swift
LazyVGrid(
    columns: [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible(), alignment: .leading)
    ],
    alignment: .leading,
    spacing: 24
)
```

注意：

- 选项文字左对齐。
- 每组选项之间垂直间距要接近截图。
- 不要使用胶囊按钮，不要给每个选项加背景。
- 每行标题与该组第一行选项顶部对齐。

### 选中态

选中项样式：

```text
▸ SDR
```

具体要求：

- 左侧有一个黄绿色小三角。
- 文字为黄绿色。
- 文字下方有黄绿色下划线。
- 下划线只覆盖文字宽度，不覆盖整列宽度。

建议颜色：

```swift
Color(red: 0.83, green: 1.0, blue: 0.35)
```

这与项目二已有 `CapsuleTheme.accent` 接近。

### 普通态

普通可选项：

- 白色文字。
- 无背景。
- 无边框。
- 无下划线。

### 禁用态

禁用项，例如截图 1 里的 `120`：

- 灰色文字。
- 不响应点击。
- 如果 `showsLockWhenDisabled == true`，文字左侧显示小锁。
- 小锁和文字一起置灰。

可用 SF Symbol：

```swift
Image(systemName: "lock.fill")
```

### Slider 行

截图 2 的“拍摄时长”行：

```text
拍摄时长    ●────────────── 180s
```

设计要求：

- 真实保存数值，范围 `0...180`。
- 右侧显示 `180s`。
- 白色圆形 thumb。
- 轨道使用低透明度黄棕色或灰绿色，接近截图里的细线。
- 行高与 options 行协调。

实现上可以先用系统 `Slider`：

```swift
Slider(value: $value, in: 0...180)
```

再通过 `.tint(...)` 调整轨道颜色。

如果系统 slider 视觉无法贴近截图，再替换成自定义 slider。

## 两个面板的数据配置

### 截图 1：VideoParameterPanel

由 `HEIF` 按钮触发。

推荐 rows：

```swift
[
    .options(
        title: "色彩空间",
        options: [
            .init(id: "SDR", title: "SDR"),
            .init(id: "HDR", title: "HDR"),
            .init(id: "Apple Log", title: "Apple Log"),
            .init(id: "Apple Log 2", title: "Apple Log 2")
        ],
        selection: $colorSpace
    ),
    .options(
        title: "编码格式",
        options: [
            .init(id: "HEVC", title: "HEVC"),
            .init(id: "ProRes Proxy", title: "ProRes Proxy"),
            .init(id: "ProRes LT", title: "ProRes LT"),
            .init(id: "ProRes", title: "ProRes"),
            .init(id: "ProRes RAW", title: "ProRes RAW")
        ],
        selection: $codec
    ),
    .options(
        title: "分辨率",
        options: [
            .init(id: "FHD", title: "FHD"),
            .init(id: "4K", title: "4K"),
            .init(id: "片门全开", title: "片门全开")
        ],
        selection: $resolution
    ),
    .options(
        title: "帧速率",
        options: [
            .init(id: "24", title: "24"),
            .init(id: "30", title: "30"),
            .init(id: "60", title: "60"),
            .init(id: "120", title: "120", isEnabled: false, showsLockWhenDisabled: true)
        ],
        selection: $frameRate
    )
]
```

初始选中值建议贴近截图：

```swift
colorSpace = "SDR"
codec = "ProRes Proxy"
resolution = "FHD"
frameRate = "24"
```

### 截图 2：TimerParameterPanel

由 `Timer` 按钮触发。

推荐 rows：

```swift
[
    .options(
        title: "拍摄间隔",
        options: [
            .init(id: "1s", title: "1s"),
            .init(id: "3s", title: "3s"),
            .init(id: "5s", title: "5s"),
            .init(id: "10s", title: "10s")
        ],
        selection: $captureInterval
    ),
    .slider(
        title: "拍摄时长",
        value: $captureDurationSeconds,
        range: 0...180,
        trailingText: "180s"
    ),
    .options(
        title: "分辨率",
        options: [
            .init(id: "FHD", title: "FHD"),
            .init(id: "4K", title: "4K"),
            .init(id: "片门全开", title: "片门全开")
        ],
        selection: $timerResolution
    )
]
```

初始选中值建议贴近截图：

```swift
captureInterval = "1s"
captureDurationSeconds = 0
timerResolution = "FHD"
```

## 父层接入方式

`ContentView` 负责保存激活面板状态和参数状态。

示意：

```swift
@State private var activeParameterPanel: ActiveParameterPanel?

@State private var colorSpace = "SDR"
@State private var codec = "ProRes Proxy"
@State private var resolution = "FHD"
@State private var frameRate = "24"

@State private var captureInterval = "1s"
@State private var captureDurationSeconds = 0.0
@State private var timerResolution = "FHD"
```

顶部按钮：

```swift
FeaturesToolbar(
    selectedFormat: selectedCaptureFormat,
    onFormatTap: { togglePanel(.video) },
    onTimerTap: { togglePanel(.timer) }
)
```

预览区域顶部：

```swift
ZStack(alignment: .top) {
    GreenPreviewPlaceholder()

    switch activeParameterPanel {
    case .video:
        VideoParameterPanel(...)
    case .timer:
        TimerParameterPanel(...)
    case .none:
        EmptyView()
    }
}
```

## 为什么不是两个完全独立的 View

可以写两个独立大 View，但不推荐。

原因：

- 两张截图的视觉结构高度一致。
- 如果复制两套布局，后续调整圆角、间距、选中样式时要改两遍。
- 后续新增第三个参数面板时，又会复制第三套。

更合理的复用边界是：

- `CaptureParameterPanel` 负责通用布局和样式。
- `VideoParameterPanel`、`TimerParameterPanel` 只负责组织数据。

这样代码既不会过度抽象，也能保持扩展性。

## 为什么不继续叫 CaptureFormatPicker

`CaptureFormatPicker` 这个名字只适合 `HEIF / JPEG` 这种单一格式选择器。

现在组件已经承载：

- 色彩空间
- 编码格式
- 分辨率
- 帧速率
- 拍摄间隔
- 拍摄时长

继续使用 `CaptureFormatPicker` 会造成语义混乱。

建议替换为：

```swift
CaptureParameterPanel
```

如果需要保留原有 `HEIF / JPEG` 小组件，也应另起名字，例如：

```swift
CaptureFormatSegmentPicker
```

但当前新需求下，旧的 `CaptureFormatPicker` 可以被新面板替代。

## 扩展性设计

后续如果要新增一个“比例”面板，只需要：

1. 在 `ActiveParameterPanel` 中加一个 case：

```swift
case ratio
```

2. 新增一个包装 View：

```swift
RatioParameterPanel
```

3. 复用同一个 `CaptureParameterPanel(rows:)`。

如果后续新增新的行类型，例如开关、步进器、颜色选择，也只需要扩展：

```swift
enum ParameterRow
```

例如：

```swift
case toggle(title: String, isOn: Binding<Bool>)
case stepper(title: String, value: Binding<Int>, range: ClosedRange<Int>)
```

这保证了组件能逐步扩展，而不是一开始就写成难以维护的万能大对象。

## 实现顺序建议

建议按以下顺序实现：

1. 新建 `FormattingTools` 下的模型和通用组件。
2. 实现 `ParameterOptionView`，先把普通态、选中态、禁用态做准。
3. 实现 `CaptureParameterPanel` 的外壳背景和 row 布局。
4. 实现 `VideoParameterPanel`，接入 `HEIF` 按钮。
5. 实现 `TimerParameterPanel`，接入 `Timer` 按钮。
6. 实现 slider 行，确保 `captureDurationSeconds` 保存真实 `0...180`。
7. 运行项目或 Preview，对照截图微调圆角、间距、字体、颜色。
8. 编译验证。

## 验收标准

功能验收：

- 点击 `HEIF`，出现截图 1 对应的参数面板。
- 点击 `Timer`，出现截图 2 对应的参数面板。
- 点击选项后，选中态立即变化，面板不收起。
- 点击不同顶部按钮时，面板内容能切换。
- `拍摄时长` slider 能保存 `0...180` 的真实值。
- 禁用的 `120` 不可点击，并显示灰色锁图标。

视觉验收：

- 面板覆盖在绿色预览顶部。
- 绿色预览背景保留。
- 面板深色半透明，底部大圆角。
- 左侧标题、右侧两列选项布局接近截图。
- 选中项有黄绿色小三角和下划线。
- 普通项白色文字，无按钮背景。
- slider 行右侧显示 `180s`。

工程验收：

- 新增代码位于 `TestAlertB/FormattingTools`。
- 父层使用 `ActiveParameterPanel?` 管理面板互斥。
- 不使用多个互斥布尔值。
- 不把两个截图面板写成完全重复的大 View。
- `xcodebuild` 编译通过。
