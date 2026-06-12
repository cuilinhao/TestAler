//
//  CameraSettingsSheet.swift
//  TestAlertB
//
//  底部弹框面板（弹框 B）：毛玻璃 + 高度自适应 + 全局互斥的形变按钮网格
//

import SwiftUI

struct CameraSettingsSheet: View {
    @Binding var isPresented: Bool
    var onCountdownFinished: () -> Void

    // 全局互斥：整个面板同一时间只允许一个按钮处于展开状态
    @State private var expandedItemID: String?
    /// 当前拍摄比例（比例 item 专用）
    @State private var aspectRatio: CameraSettings.AspectRatio = .ratio4x3
    /// 倒计时选项枚举：关闭 / 3秒 / 10秒；运行结束后会重置为 .off
    @State private var countdown: CameraSettings.Countdown = .off
    /// 倒计时进行中剩余秒数；nil 表示未在倒计时（收起态显示斜杠 timer）
    @State private var countdownRemainingSeconds: Int?
    /// 每秒递减的异步 Task；取消 sheet 或重选选项时需 cancel
    @State private var countdownTask: Task<Void, Never>?
    @State private var optionSelections: [String: String] = [:]
    @State private var enabledToggles: Set<String> = []
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
    
    ///弹框dismiss的时间
    /// response 可以理解成弹簧反应时间，越大越慢
    private let dismissalAnimation = Animation.spring(response: 1.0, dampingFraction: 0.9)
    // 等退场动画基本结束后再从视图树移除，避免过早移除导致底部出现残影。
    private let dismissalCleanupDelay = 0.75

    /// 倒计时是否正在运行；运行中禁止 timer 胶囊再次展开
    private var isCountdownRunning: Bool {
        countdownRemainingSeconds != nil
    }

    /// 多行不等列布局：2 / 3 / 3 / 2，每行内部平分宽度
    private static let rows: [[SettingItem]] = [
        [
            .init(id: CameraSettings.ItemID.ratio.rawValue, kind: .options(CameraSettings.AspectRatio.allCases.map(\.rawValue)), position: .left),
            .init(id: CameraSettings.ItemID.timer.rawValue, kind: .options(CameraSettings.Countdown.allCases.map(\.rawValue)), position: .right),
        ],
        [
            .init(id: CameraSettings.ItemID.live.rawValue, kind: .options(["极限", "自动", "关闭", "标准", "运动"]), position: .left),
            .init(id: CameraSettings.ItemID.grid.rawValue, kind: .options(["1:1", "4:3", "16:9", "4:5", "5:6", "8:9"]), position: .center),
            .init(id: CameraSettings.ItemID.level.rawValue, kind: .toggle, position: .right),
        ],
        [
            .init(id: CameraSettings.ItemID.histogram.rawValue, kind: .toggle, position: .left),
            .init(id: CameraSettings.ItemID.focusAssist.rawValue, kind: .toggle, position: .center),
            .init(id: CameraSettings.ItemID.watermark.rawValue, kind: .toggle, position: .right),
        ],
        [
            .init(id: CameraSettings.ItemID.telephoto.rawValue, kind: .toggle, position: .left),
            .init(id: CameraSettings.ItemID.diving.rawValue, kind: .toggle, position: .right),
        ],
        [
            .init(id: CameraSettings.ItemID.voice.rawValue, kind: .options(["极限", "自动", "关闭", "标准", "运动"]), position: .left),
        ],
    ]

    var body: some View {
        GeometryReader { screen in
            // 边界阈值：屏幕高度的 60%
            let maxSheetHeight = screen.size.height * 0.6
            // 内容真实高度超过阈值 -> 锁定 60% 并启用内部滚动
            let needsScroll = contentHeight + grabberZoneHeight > maxSheetHeight

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

            if needsScroll {
                ScrollView(showsIndicators: false) { settingsGrid }
            } else {
                // 内容不超阈值：Sheet 高度 = 真实高度，禁止滚动
                settingsGrid
            }
        }
        .frame(height: needsScroll ? maxHeight : nil)
        .frame(maxWidth: .infinity)
        .background(
            // 深色毛玻璃 + 顶部 32 圆角，向下延伸覆盖底部安全区
            UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .ignoresSafeArea(edges: .bottom)
        )
        // 展开状态下点击面板空白处：立即收回展开的胶囊
        // （按钮自身的点击优先于此手势，互不冲突）
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

     //MARK: - 将item数据放在UI上
    private var settingsGrid: some View {
        VStack(spacing: 12) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { rowIndex, row in
                let expandedIDInRow = row.first { $0.id == expandedItemID }?.id

                HStack(spacing: 12) {
                    ForEach(row) { item in
                        settingCapsuleButton(
                            for: item,
                            rowItemCount: row.count,
                            rowIndex: rowIndex,
                            expandedIDInRow: expandedIDInRow
                        )
                    }
                }
                .onAppear {
                    TestLog.log(
                        "row appear index=\(rowIndex), paintOrder=\(debugRowDescription(row))"
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        // PreferenceKey 方案测量内容真实高度，驱动 Sheet 高度自适应
        .measureHeight($contentHeight)
    }

    /// 根据 option 数量自动选择胶囊组件，并统一处理同行兄弟覆盖逻辑
    @ViewBuilder
    private func settingCapsuleButton(
        for item: SettingItem,
        rowItemCount: Int,
        rowIndex: Int,
        expandedIDInRow: String?
    ) -> some View {
        // 同一行有 item 展开时，其余兄弟 item 隐藏且不可点击，避免与展开胶囊叠层冲突
        let isCoveredByExpandedSibling = expandedIDInRow != nil && expandedIDInRow != item.id
        let isItemTapEnabled = isTapEnabled(for: item)

        Group {
            if case .options(let opts) = item.kind, opts.count > 3 {
                // 选项 > 3：使用多选项滑动胶囊（如「网格」6 个比例）
                MultipleCapsuleButton(
                    item: item,
                    rowItemCount: rowItemCount,
                    isExpanded: expandedItemID == item.id,
                    isOn: enabledToggles.contains(item.id),
                    selectedOption: selectedOption(for: item),
                    countdownRemainingSeconds: countdownRemainingSeconds(for: item),
                    isTapEnabled: isItemTapEnabled,
                    onTap: { handleTap(item) },
                    onSelect: { option in select(option, for: item) }
                )
            } else {
                // toggle 或 options ≤ 3：使用原形变分段胶囊（如「比例」「倒计时」）
                MorphingCapsuleButton(
                    item: item,
                    rowItemCount: rowItemCount,
                    isExpanded: expandedItemID == item.id,
                    isOn: enabledToggles.contains(item.id),
                    selectedOption: selectedOption(for: item),
                    countdownRemainingSeconds: countdownRemainingSeconds(for: item),
                    isTapEnabled: isItemTapEnabled,
                    onTap: { handleTap(item) },
                    onSelect: { option in select(option, for: item) }
                )
            }
        }
        .zIndex(expandedItemID == item.id ? 10 : 0)
        .opacity(isCoveredByExpandedSibling ? 0 : 1)
        .allowsHitTesting(!isCoveredByExpandedSibling && isItemTapEnabled)
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

    /// 仅 timer item 需要传入剩余秒数，驱动 CountdownCollapsedView
    private func countdownRemainingSeconds(for item: SettingItem) -> Int? {
        item.itemID == .timer ? countdownRemainingSeconds : nil
    }

    /// 倒计时进行中禁止 timer 点击展开；其余 item 不受影响
    private func isTapEnabled(for item: SettingItem) -> Bool {
        item.itemID != .timer || !isCountdownRunning
    }

    private func selectedOption(for item: SettingItem) -> String? {
        switch item.itemID {
        case .ratio:
            return aspectRatio.rawValue
        case .timer:
            return countdown.rawValue
        default:
            return optionSelections[item.id]
        }
    }

    private func handleTap(_ item: SettingItem) {
        if item.itemID == .timer, isCountdownRunning {
            TestLog.log("handleTap blocked, countdown running")
            return
        }

        TestLog.log(
            "handleTap id=\(item.id), title=\(item.title), kind=\(debugKindDescription(item.kind)), position=\(debugPositionDescription(item.position)), expandedBefore=\(expandedItemID ?? "nil"), rowOrder=\(debugRowDescription(containing: item)), selected=\(selectedOption(for: item) ?? "nil"), toggles=\(debugToggleDescription())"
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            switch item.kind {
            case .options:
                expandedItemID = item.id
            case .toggle:
                expandedItemID = nil
                if enabledToggles.contains(item.id) {
                    enabledToggles.remove(item.id)
                } else {
                    enabledToggles.insert(item.id)
                }
            }
        }

        TestLog.log(
            "handleTap scheduled id=\(item.id), expandedAfter=\(expandedItemID ?? "nil"), toggles=\(debugToggleDescription())"
        )
    }

    private func select(_ option: String, for item: SettingItem) {
        TestLog.log(
            "select option=\(option), id=\(item.id), previous=\(selectedOption(for: item) ?? "nil"), expandedBefore=\(expandedItemID ?? "nil")"
        )

        // 倒计时选项：选「关闭」立即取消；选 3秒/10秒 先收起胶囊再开始递减
        if item.itemID == .timer, let value = CameraSettings.Countdown(rawValue: option) {
            if value == .off {
                cancelCountdown()
                countdown = .off
            } else if let duration = value.durationSeconds {
                // 运行态不保留「3秒/10秒」选中项，UI 由 countdownRemainingSeconds 驱动
                countdown = .off
                collapseAfterSelection(item: item, option: option) {
                    startCountdown(duration: duration)
                }
                return
            }
        }

        switch item.itemID {
        case .ratio:
            if let value = CameraSettings.AspectRatio(rawValue: option) {
                aspectRatio = value
            }
        default:
            optionSelections[item.id] = option
        }

        collapseAfterSelection(item: item, option: option)
    }

    private func collapseAfterSelection(item: SettingItem, option: String, completion: (() -> Void)? = nil) {
        // 选择后延迟 0.2 秒，胶囊原路收缩回普通按钮
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                expandedItemID = nil
            }
            TestLog.log(
                "select collapse id=\(item.id), option=\(option), expandedAfter=\(expandedItemID ?? "nil")"
            )
            completion?()
        }
    }

    /// 启动拍照倒计时：每秒更新 remaining，结束后回调 onCountdownFinished
    /// 面板收起后 Task 仍继续，直到 completeCountdown
    private func startCountdown(duration: Int) {
        cancelCountdown()
        countdownRemainingSeconds = duration

        countdownTask = Task { @MainActor in
            // 3 → 2 → 1，每步 sleep 1 秒并刷新收起态圆 badge
            for remaining in stride(from: duration, through: 1, by: -1) {
                countdownRemainingSeconds = remaining
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
            }
            completeCountdown()
        }
    }

    /// 取消进行中的倒计时 Task，并清空剩余秒数
    private func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        countdownRemainingSeconds = nil
    }

    /// 倒计时自然结束：回到关闭态并通知上层触发拍照
    private func completeCountdown() {
        cancelCountdown()
        countdown = .off
        onCountdownFinished()
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

    private func debugPositionDescription(_ position: ButtonPosition) -> String {
        switch position {
        case .left:
            return "left"
        case .center:
            return "center"
        case .right:
            return "right"
        }
    }

    private func debugRowDescription(containing item: SettingItem) -> String {
        guard let row = Self.rows.first(where: { row in
            row.contains { $0.id == item.id }
        }) else {
            return "unknown"
        }

        return debugRowDescription(row)
    }

    private func debugRowDescription(_ row: [SettingItem]) -> String {
        return row.map(\.id).joined(separator: " -> ")
    }

    private func debugToggleDescription() -> String {
        guard !enabledToggles.isEmpty else { return "[]" }
        return "[\(enabledToggles.sorted().joined(separator: ","))]"
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
