//
//  CameraSettingsSheet.swift
//  TestAlertB
//
//  底部弹框面板（弹框 B）：毛玻璃 + 高度自适应 + 全局互斥的形变按钮网格
//

import SwiftUI

struct CameraSettingsSheet: View {
    @Binding var isPresented: Bool
    var mode: CameraSettings.SheetMode = .photo
    /// 比例：由外部持有，Sheet 内选中时同步回写
    @Binding var aspectRatios: [CameraSettings.SheetMode: CameraSettings.AspectRatio]
    /// 选项选中值：由外部持有，Sheet 内选中时同步回写
    @Binding var optionSelectionsByMode: [CameraSettings.SheetMode: [String: String]]

    /// 弹框内部页面：只切换内容区，不改变外层 Sheet 样式
    private enum SheetPage {
        case main
        case watermark
    }

    // 全局互斥：整个面板同一时间只允许一个按钮处于展开状态
    @State private var expandedItemID: String?
    /// 倒计时选中项：关闭 / 3秒 / 10秒，仅更新文案不启动 timer
    @State private var countdown: CameraSettings.Countdown = .off
    @State private var enabledTogglesByMode: [CameraSettings.SheetMode: Set<String>] = [:]
    /// 当前内容页：主设置页 / 水印页
    @State private var currentPage: SheetPage = .main
    /// 水印模板选中 index，与子页共享
    @State private var selectedWatermarkIndex = 0
    // 通过 PreferenceKey 测得的网格内容真实高度
    @State private var contentHeight: CGFloat = 0
    // 下滑手势的实时位移
    @State private var dragOffset: CGFloat = 0
    // 呈现生命周期拆分：isPresented 表示外部意图，isRendered 表示视图是否仍保留在树中
    @State private var isRendered = false
    @State private var sheetOffset: CGFloat = 0
    @State private var backdropOpacity: Double = 0

    /// 顶部拖拽指示条区域的固定高度（参与 Sheet 总高度计算）
    private let grabberZoneHeight: CGFloat = 32
    private let visibleBackdropOpacity = 0.35
    // 入场保持轻快，避免点击按钮 A 后弹框响应显得拖沓。
    private let presentationAnimation = Animation.spring(response: 0.4, dampingFraction: 0.85)
    // 内容区 Push/Pop 动画，外层 Sheet 不跟着变形。
    private let pageAnimation = Animation.easeInOut(duration: 0.28)
    
    ///弹框dismiss的时间
    /// response 可以理解成弹簧反应时间，越大越慢
    private let dismissalAnimation = Animation.spring(response: 1.0, dampingFraction: 0.9)
    // 等退场动画基本结束后再从视图树移除，避免过早移除导致底部出现残影。
    private let dismissalCleanupDelay = 0.75

    /// 当前模式的数据源：同一个 Sheet 复用布局和交互，只替换 item rows
    private var rows: [SettingRow] {
        switch mode {
        case .photo:
            return Self.photoRows
        case .video:
            return Self.videoRows
        
        default:
            return Self.videoRows
        }
    }

    /// 拍照设置：按小格行 / 大格行拼装
    private static let photoRows: [SettingRow] = [
        SettingRow(layout: .large, items: [
            .init(id: CameraSettings.ItemID.ratio.rawValue, kind: .options(CameraSettings.AspectRatio.allCases.map(\.rawValue))),
            .init(id: CameraSettings.ItemID.timer.rawValue, kind: .options(CameraSettings.Countdown.allCases.map(\.rawValue))),
        ]),
        SettingRow(layout: .small, items: [
            .init(id: CameraSettings.ItemID.live.rawValue, kind: .toggle),
            .init(id: CameraSettings.ItemID.grid.rawValue, kind: .options(["1:1", "4:3", "16:9", "4:5", "5:6", "8:9"])),
            .init(id: CameraSettings.ItemID.level.rawValue, kind: .toggle),
        ]),
        SettingRow(layout: .small, items: [
            .init(id: CameraSettings.ItemID.histogram.rawValue, kind: .toggle),
            .init(id: CameraSettings.ItemID.focusAssist.rawValue, kind: .toggle),
            .init(id: CameraSettings.ItemID.watermark.rawValue, kind: .toggle),
        ]),
        SettingRow(layout: .large, items: [
            .init(id: CameraSettings.ItemID.telephoto.rawValue, kind: .toggle),
            .init(id: CameraSettings.ItemID.diving.rawValue, kind: .toggle),
        ]),
    ]

    /// 录像设置：按小格行 / 大格行拼装
    private static let videoRows: [SettingRow] = [
        SettingRow(layout: .large, items: [
            .init(id: CameraSettings.ItemID.ratio.rawValue, kind: .options(CameraSettings.AspectRatio.allCases.map(\.rawValue))),
            .init(id: CameraSettings.ItemID.level.rawValue, kind: .toggle),
        ]),
        SettingRow(layout: .small, items: [
            .init(id: CameraSettings.ItemID.grid.rawValue, kind: .toggle),
            .init(id: CameraSettings.ItemID.histogram.rawValue, kind: .toggle),
            .init(id: CameraSettings.ItemID.logRestore.rawValue, kind: .options(["仅预览", "烧录至成品"])),
        ]),
        SettingRow(layout: .small, items: [
            .init(id: CameraSettings.ItemID.voice.rawValue, kind: .toggle),
            .init(id: CameraSettings.ItemID.focusAssist.rawValue, kind: .toggle),
            .init(id: CameraSettings.ItemID.stabilization.rawValue, kind: .options(["极限", "自动", "关闭", "标准", "运动"])),
        ]),
        SettingRow(layout: .large, items: [
            .init(id: CameraSettings.ItemID.telephoto.rawValue, kind: .toggle),
            .init(id: CameraSettings.ItemID.diving.rawValue, kind: .toggle),
        ]),
    ]

    var body: some View {
        GeometryReader { screen in
            // 边界阈值：屏幕高度的 60%
            let maxSheetHeight = screen.size.height * 0.6
            // 内容真实高度超过阈值 -> 锁定 60% 并启用内部滚动
            let activeContentHeight = contentHeight
            let needsScroll = activeContentHeight + grabberZoneHeight > maxSheetHeight

            ZStack(alignment: .bottom) {
                if isRendered {
                    // 暗色遮罩：点击面板外部区域自动收回
                    Color.black.opacity(backdropOpacity)
                        .ignoresSafeArea()
                        .onTapGesture {
                            TestLog.log(
                                "backdrop tap -> dismiss, isPresented=\(isPresented), expanded=\(expandedItemID ?? "nil"), dragOffset=\(debugNumber(dragOffset))"
                            )
                            dismiss(screenHeight: screen.size.height)
                        }
                        .onAppear {
                            TestLog.log("backdrop appear")
                        }
                        .onDisappear {
                            TestLog.log("backdrop disappear")
                        }

                    sheetPanel(
                        maxHeight: maxSheetHeight,
                        needsScroll: needsScroll,
                        screenHeight: screen.size.height
                    )
                        .onAppear {
                            TestLog.log(
                                "sheet transition appear, screen=\(debugSize(screen.size)), safeAreaBottom=\(debugNumber(screen.safeAreaInsets.bottom)), maxSheetHeight=\(debugNumber(maxSheetHeight)), contentHeight=\(debugNumber(contentHeight)), grabberZoneHeight=\(debugNumber(grabberZoneHeight)), needsScroll=\(needsScroll)"
                            )
                        }
                        .onDisappear {
                            TestLog.log(
                                "sheet transition disappear, screen=\(debugSize(screen.size)), safeAreaBottom=\(debugNumber(screen.safeAreaInsets.bottom)), maxSheetHeight=\(debugNumber(maxSheetHeight)), contentHeight=\(debugNumber(contentHeight)), dragOffset=\(debugNumber(dragOffset)), isPresented=\(isPresented)"
                            )
                        }
                        .offset(y: max(sheetOffset, 0))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .onAppear {
                TestLog.log(
                    "container appear, screen=\(debugSize(screen.size)), safeAreaBottom=\(debugNumber(screen.safeAreaInsets.bottom)), maxSheetHeight=\(debugNumber(maxSheetHeight)), contentHeight=\(debugNumber(contentHeight)), needsScroll=\(needsScroll), isPresented=\(isPresented)"
                )
                if isPresented {
                    present(screenHeight: screen.size.height)
                }
            }
            .onChange(of: isPresented) { newValue in
                TestLog.log(
                    "isPresented changed=\(newValue), screen=\(debugSize(screen.size)), safeAreaBottom=\(debugNumber(screen.safeAreaInsets.bottom)), maxSheetHeight=\(debugNumber(maxSheetHeight)), contentHeight=\(debugNumber(contentHeight)), needsScroll=\(needsScroll), dragOffset=\(debugNumber(dragOffset))"
                )
                if newValue {
                    present(screenHeight: screen.size.height)
                } else {
                    runDismissAnimation(screenHeight: screen.size.height)
                }
            }
            .onChange(of: contentHeight) { newValue in
                TestLog.log(
                    "contentHeight changed=\(debugNumber(newValue)), screen=\(debugSize(screen.size)), maxSheetHeight=\(debugNumber(maxSheetHeight)), needsScroll=\(needsScroll)"
                )
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: expandedItemID)
    }

    // MARK: - 面板主体

    private func sheetPanel(maxHeight: CGFloat, needsScroll: Bool, screenHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            // 顶部拖拽指示条 (Grabber)
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 5)
                .frame(height: grabberZoneHeight)

            sheetContent(maxHeight: maxHeight, needsScroll: needsScroll)
        }
        .frame(height: needsScroll ? maxHeight : nil)
        .frame(maxWidth: .infinity)
        .background(
            // 外层 Sheet 始终保持毛玻璃样式，子页只替换内部内容。
            UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .ignoresSafeArea(edges: .bottom)
        )
        // 展开状态下点击面板空白处：立即收回展开的胶囊（子页无展开态，不影响）
        .contentShape(Rectangle())
        .onTapGesture {
            TestLog.log("sheetPanel tap, expanded=\(expandedItemID ?? "nil")")
            collapseExpanded()
        }
        .offset(y: max(dragOffset, 0))
        .gesture(dragToDismiss(screenHeight: screenHeight))
        .onAppear {
            TestLog.log(
                "sheetPanel appear, maxHeight=\(debugNumber(maxHeight)), needsScroll=\(needsScroll), contentHeight=\(debugNumber(contentHeight)), grabberZoneHeight=\(debugNumber(grabberZoneHeight)), dragOffset=\(debugNumber(dragOffset)), backgroundIgnoresBottomSafeArea=true"
            )
        }
        .onDisappear {
            TestLog.log(
                "sheetPanel disappear, maxHeight=\(debugNumber(maxHeight)), needsScroll=\(needsScroll), contentHeight=\(debugNumber(contentHeight)), dragOffset=\(debugNumber(dragOffset)), isPresented=\(isPresented)"
            )
        }
    }

    /// 内容区横向 Push/Pop；高度沿用主设置网格，避免进入水印页后 Sheet 变高/变矮。
    private func sheetContent(maxHeight: CGFloat, needsScroll: Bool) -> some View {
        let fixedHeight: CGFloat? = needsScroll
            ? max(maxHeight - grabberZoneHeight, 0)
            : (contentHeight > 0 ? contentHeight : nil)

        return ZStack(alignment: .top) {
             //MARK: -水印页面和列表页面分开展示在同一个主view上-
            if currentPage == .main {
                mainSettingsContent(needsScroll: needsScroll)
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
                    .zIndex(currentPage == .main ? 1 : 0)
            }

            if currentPage == .watermark {
                WatermarkSettingsView(
                    isEnabled: watermarkEnabledBinding,
                    selectedIndex: $selectedWatermarkIndex,
                    onBack: showMainSettings
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                .zIndex(currentPage == .watermark ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: fixedHeight, alignment: .top)
        .clipped()
        .animation(pageAnimation, value: currentPage)
    }

    /// @ViewBuilder 允许函数内多分支、if/else 返回不同 View
    @ViewBuilder
    private func mainSettingsContent(needsScroll: Bool) -> some View {
        if needsScroll {
            ScrollView(showsIndicators: false) { settingsGrid }
        } else {
            settingsGrid
        }
    }

     //MARK: - 将 item 数据按小格行 / 大格行拼到 UI 上
    private var settingsGrid: some View {
        VStack(spacing: 12) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { rowIndex, row in
                settingGridRow(row, rowIndex: rowIndex)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .measureHeight($contentHeight)
    }

    /// 按行布局选择小格行或大格行容器
    @ViewBuilder
    private func settingGridRow(_ row: SettingRow, rowIndex: Int) -> some View {
        let expandedIDInRow = row.items.first { $0.id == expandedItemID }?.id

        switch row.layout {
        case .small:
            ///
            SmallSettingRowView(items: row.items, rowIndex: rowIndex) { item, _, position in
                settingCapsuleButton(
                    for: item,
                    columnCount: row.layout.columnCount,
                    position: position,
                    rowIndex: rowIndex,
                    expandedIDInRow: expandedIDInRow
                )
            }
        case .large:
            LargeSettingRowView(items: row.items, rowIndex: rowIndex) { item, _, position in
                settingCapsuleButton(
                    for: item,
                    columnCount: row.layout.columnCount,
                    position: position,
                    rowIndex: rowIndex,
                    expandedIDInRow: expandedIDInRow
                )
            }
        }
    }

    /// 单个格子的胶囊：小格 / 大格共用，由 columnCount 区分展开宽度
    @ViewBuilder
    private func settingCapsuleButton(
        for item: SettingItem,
        columnCount: Int,
        position: ButtonPosition,
        rowIndex: Int,
        expandedIDInRow: String?
    ) -> some View {
        // 同一行有 item 展开时，其余兄弟 item 隐藏且不可点击，避免与展开胶囊叠层冲突
        let isCoveredByExpandedSibling = expandedIDInRow != nil && expandedIDInRow != item.id

        Group {
            if case .options(let opts) = item.kind, opts.count > 3 {
                // 选项 > 3：横向滑动胶囊
                MultipleCapsuleButton(
                    item: item,
                    columnCount: columnCount,
                    position: position,
                    isExpanded: expandedItemID == item.id,
                    isOn: currentEnabledToggles.contains(item.id),
                    selectedOption: selectedOption(for: item),
                    isTapEnabled: true,
                    onTap: { handleTap(item) },
                    onSelect: { option in select(option, for: item) }
                )
            } else {
                // toggle 或 options ≤ 3：分段形变胶囊
                MorphingCapsuleButton(
                    item: item,
                    columnCount: columnCount,
                    position: position,
                    isExpanded: expandedItemID == item.id,
                    isOn: currentEnabledToggles.contains(item.id),
                    selectedOption: selectedOption(for: item),
                    isTapEnabled: true,
                    onTap: { handleTap(item) },
                    onSelect: { option in select(option, for: item) }
                )
            }
        }
        .zIndex(expandedItemID == item.id ? 10 : 0)
        .opacity(isCoveredByExpandedSibling ? 0 : 1)
        .allowsHitTesting(!isCoveredByExpandedSibling)
        .accessibilityHidden(isCoveredByExpandedSibling)
        .onChange(of: isCoveredByExpandedSibling) { isCovered in
            TestLog.log(
                "row sibling coverage item=\(item.id), rowIndex=\(rowIndex), expandedIDInRow=\(expandedIDInRow ?? "nil"), isCovered=\(isCovered)"
            )
        }
    }

    // MARK: - 手势

    private func dragToDismiss(screenHeight: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                TestLog.log(
                    "drag ended, translationHeight=\(debugNumber(value.translation.height)), threshold=100, willDismiss=\(value.translation.height > 100)"
                )

                if value.translation.height > 100 {
                    dismiss(screenHeight: screenHeight)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - 状态流转

    private var currentAspectRatio: CameraSettings.AspectRatio {
        aspectRatios[mode] ?? CameraSettings.AspectRatio.defaultValue
    }

    private var currentOptionSelections: [String: String] {
        optionSelectionsByMode[mode] ?? [:]
    }

    private var currentEnabledToggles: Set<String> {
        enabledTogglesByMode[mode] ?? []
    }

    private func selectedOption(for item: SettingItem) -> String? {
        switch item.itemID {
        case .ratio:
            return currentAspectRatio.rawValue
        case .timer:
            return countdown.rawValue
        default:
            return currentOptionSelections[item.id]
        }
    }

    private func setCurrentAspectRatio(_ value: CameraSettings.AspectRatio) {
        aspectRatios[mode] = value
    }

    private func setOptionSelection(_ option: String, for item: SettingItem) {
        var selections = currentOptionSelections
        selections[item.id] = option
        optionSelectionsByMode[mode] = selections
    }

    private func toggleCurrentModeItem(_ id: String) {
        var toggles = currentEnabledToggles
        if toggles.contains(id) {
            toggles.remove(id)
        } else {
            toggles.insert(id)
        }
        enabledTogglesByMode[mode] = toggles
    }

    private func setCurrentModeToggle(_ id: String, isOn: Bool) {
        var toggles = currentEnabledToggles
        if isOn {
            toggles.insert(id)
        } else {
            toggles.remove(id)
        }
        enabledTogglesByMode[mode] = toggles
    }

     //MARK: - 点击item 后走这里 -
    private func handleTap(_ item: SettingItem) {
        TestLog.log(
            "handleTap id--- =\(item.id), title=\(item.title), kind=\(debugKindDescription(item.kind)), expandedBefore=\(expandedItemID ?? "nil"), rowOrder=\(debugRowDescription(containing: item)), selected=\(selectedOption(for: item) ?? "nil"), toggles=\(debugToggleDescription())"
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            switch item.kind {
            case .options:
                expandedItemID = item.id
            case .toggle:
                // 水印：Push 子页，不在主网格里直接 toggle
                if item.itemID == .watermark {
                    expandedItemID = nil
                    currentPage = .watermark
                    break
                }
                expandedItemID = nil
                toggleCurrentModeItem(item.id)
            }
        }

        TestLog.log(
            "handleTap scheduled id=\(item.id), expandedAfter=\(expandedItemID ?? "nil"), toggles=\(debugToggleDescription())"
        )
    }
    
     //MARK: - 展开的胶囊， 选择某一个数据后触发
    private func select(_ option: String, for item: SettingItem) {
        TestLog.log(
            "select option=\(option), id=\(item.id), previous=\(selectedOption(for: item) ?? "nil"), expandedBefore=\(expandedItemID ?? "nil")"
        )

        switch item.itemID {
        case .ratio:
            if let value = CameraSettings.AspectRatio(rawValue: option) {
                setCurrentAspectRatio(value)
            }
        case .timer:
            if let value = CameraSettings.Countdown(rawValue: option) {
                countdown = value
            }
        default:
            setOptionSelection(option, for: item)
        }

        collapseAfterSelection(item: item, option: option)
    }

    private func collapseAfterSelection(item: SettingItem, option: String) {
        // 选择后延迟 0.2 秒，胶囊原路收缩回普通按钮
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                expandedItemID = nil
            }
            TestLog.log(
                "select collapse id=\(item.id), option=\(option), expandedAfter=\(expandedItemID ?? "nil")"
            )
        }
    }

    private func showMainSettings() {
        withAnimation(pageAnimation) {
            currentPage = .main
        }
    }

    /// 水印开关与当前模式的主网格开关状态同步
    private var watermarkEnabledBinding: Binding<Bool> {
        let id = CameraSettings.ItemID.watermark.rawValue
        return Binding(
            get: { currentEnabledToggles.contains(id) },
            set: { isOn in
                setCurrentModeToggle(id, isOn: isOn)
            }
        )
    }

    private func collapseExpanded() {
        guard expandedItemID != nil else { return }
        TestLog.log("collapseExpanded expandedBefore=\(expandedItemID ?? "nil")")

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            expandedItemID = nil
        }
    }

    private func dismiss(screenHeight: CGFloat) {
        TestLog.log("dismiss expandedBefore=\(expandedItemID ?? "nil"), dragOffset=\(dragOffset)")

        if isPresented {
            isPresented = false
        } else {
            runDismissAnimation(screenHeight: screenHeight)
        }

        TestLog.log(
            "dismiss state set, expandedAfter=\(expandedItemID ?? "nil"), isPresented=\(isPresented), dragOffset=\(debugNumber(dragOffset))"
        )
    }

    private func present(screenHeight: CGFloat) {
        TestLog.log(
            "present start, screenHeight=\(debugNumber(screenHeight)), isRendered=\(isRendered), sheetOffset=\(debugNumber(sheetOffset)), backdropOpacity=\(backdropOpacity)"
        )

        if !isRendered {
            isRendered = true
            currentPage = .main
            contentHeight = 0
            sheetOffset = screenHeight
            backdropOpacity = 0
        }

        DispatchQueue.main.async {
            withAnimation(presentationAnimation) {
                sheetOffset = 0
                backdropOpacity = visibleBackdropOpacity
                dragOffset = 0
            }

            TestLog.log(
                "present animated, sheetOffset=\(debugNumber(sheetOffset)), backdropOpacity=\(backdropOpacity), isRendered=\(isRendered)"
            )
        }
    }

    private func runDismissAnimation(screenHeight: CGFloat) {
        guard isRendered else {
            TestLog.log("dismiss animation skipped, isRendered=false")
            return
        }

        TestLog.log(
            "dismiss animation start, screenHeight=\(debugNumber(screenHeight)), sheetOffset=\(debugNumber(sheetOffset)), dragOffset=\(debugNumber(dragOffset)), backdropOpacity=\(backdropOpacity)"
        )
        // 退场只改变偏移和遮罩透明度，真正移除视图放到 cleanup 阶段。
        withAnimation(dismissalAnimation) {
            expandedItemID = nil
            sheetOffset = screenHeight
            backdropOpacity = 0
            dragOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + dismissalCleanupDelay) {
            guard !isPresented else {
                TestLog.log("+++ dismiss animation cleanup skipped, isPresented=true")
                return
            }

            isRendered = false
            sheetOffset = 0
            backdropOpacity = 0
            dragOffset = 0
            currentPage = .main
            selectedWatermarkIndex = 0

            TestLog.log(
                "+++ dismiss animation cleanup, isRendered=\(isRendered), sheetOffset=\(debugNumber(sheetOffset)), backdropOpacity=\(backdropOpacity), dragOffset=\(debugNumber(dragOffset))"
            )
        }
    }

    private func debugKindDescription(_ kind: SettingItemKind) -> String {
        switch kind {
        case .toggle:
            return "toggle"
        case .options(let options):
            return "options(\(options.joined(separator: "/")))"
        }
    }

    private func debugRowDescription(containing item: SettingItem) -> String {
        guard let row = rows.first(where: { row in
            row.items.contains { $0.id == item.id }
        }) else {
            return "unknown"
        }

        return debugRowDescription(row)
    }

    private func debugRowDescription(_ row: SettingRow) -> String {
        return row.items.map(\.id).joined(separator: " -> ")
    }

    private func debugToggleDescription() -> String {
        let toggles = currentEnabledToggles
        guard !toggles.isEmpty else { return "[]" }
        return "[\(toggles.sorted().joined(separator: ","))]"
    }

    private func debugSize(_ size: CGSize) -> String {
        "\(debugNumber(size.width))x\(debugNumber(size.height))"
    }

    private func debugNumber(_ value: CGFloat) -> String {
        let rounded = (Double(value) * 10).rounded() / 10
        return "\(rounded)"
    }
}

// MARK: - 高度测量（PreferenceKey 方案）

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// 用 GeometryReader 包裹在 background 中测量视图真实高度，不影响布局
    func measureHeight(_ height: Binding<CGFloat>) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(key: HeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self) { newHeight in
            TestLog.log("measureHeight changed=\(newHeight)")
            height.wrappedValue = newHeight
        }
    }
}
