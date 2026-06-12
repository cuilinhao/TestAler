//
//  CameraSettingsSheet.swift
//  TestAlertB
//
//  底部弹框面板（弹框 B）：毛玻璃 + 高度自适应 + 全局互斥的形变按钮网格
//

import SwiftUI

struct CameraSettingsSheet: View {
    @Binding var isPresented: Bool

    // 全局互斥：整个面板同一时间只允许一个按钮处于展开状态
    @State private var expandedItemID: String?
    // 核心数据：选项选择 / 开关状态。UI 完全由这两份数据推导，不维护中间 UI 状态
    @State private var optionSelections: [String: String] = ["ratio": "4:3", "timer": "关闭"]
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

    /// 多行不等列布局：2 / 3 / 3 / 2，每行内部平分宽度
    private static let rows: [[SettingItem]] = [
        [
            .init(id: "ratio", icon: "aspectratio", title: "比例", kind: .options(["1:1", "4:3", "16:9"]), position: .left),
            .init(id: "timer", icon: "timer", title: "倒计时", kind: .options(["关闭", "3秒", "10秒"]), position: .right),
        ],
        [
            //.init(id: "live", icon: "livephoto.slash", title: "LIVE", kind: .toggle, position: .left),
            //极限 自动 关闭 标准 运动
            .init(id: "live", icon: "livephoto.slash", title: "LIVE", kind: .options(["极限", "自动", "关闭", "标准", "运动"]), position: .left),
            
            //.init(id: "grid", icon: "grid", title: "网格", kind: .toggle, position: .center),
            .init(id: "grid", icon: "grid", title: "网格", kind: .options(["1:1", "4:3", "16:9","4:5", "5:6", "8:9"]), position: .center),
            
            .init(id: "level", icon: "smallcircle.filled.circle", title: "水平仪", kind: .toggle, position: .right),
        ],
        [
            .init(id: "histogram", icon: "chart.bar.fill", title: "直方图", kind: .toggle, position: .left),
            .init(id: "focusAssist", icon: "camera.metering.spot", title: "对焦辅助", kind: .toggle, position: .center),
            .init(id: "watermark", icon: "water.waves", title: "水印", kind: .toggle, position: .right),
        ],
        [
            .init(id: "telephoto", icon: "plus.magnifyingglass", title: "长焦模式", kind: .toggle, position: .left),
            .init(id: "diving", icon: "drop", title: "潜水模式", kind: .toggle, position: .right),
        ],
        [.init(id: "voice", icon: "livephoto.slash", title: "音频", kind: .options(["极限", "自动", "关闭", "标准", "运动"]), position: .left),]
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
                .background {
                    if rowIndex == 1 {
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    TestLog.log(
                                        "rowContainer row=\(rowIndex) width=\(debugNumber(proxy.size.width)), itemCount=\(row.count), paintOrder=\(debugRowDescription(row))"
                                    )
                                }
                                .onChange(of: proxy.size.width) { newWidth in
                                    TestLog.log(
                                        "rowContainer row=\(rowIndex) widthChanged=\(debugNumber(newWidth)), expandedID=\(expandedItemID ?? "nil")"
                                    )
                                }
                        }
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
        // 命名坐标系：供 itemFrame 日志读取同一参考系下的 minX / width
        .coordinateSpace(name: "settingsGrid")
        .onPreferenceChange(ItemFramePreferenceKey.self) { frames in
            logItemFrames(frames)
        }
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
        let componentName: String = {
            if case .options(let opts) = item.kind, opts.count > 3 { return "Multiple" }
            return "Morphing"
        }()

        Group {
            if case .options(let opts) = item.kind, opts.count > 3 {
                // 选项 > 3：使用多选项滑动胶囊（如「网格」6 个比例）
                MultipleCapsuleButton(
                    item: item,
                    rowItemCount: rowItemCount,
                    isExpanded: expandedItemID == item.id,
                    isOn: enabledToggles.contains(item.id),
                    selectedOption: optionSelections[item.id],
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
                    selectedOption: optionSelections[item.id],
                    onTap: { handleTap(item) },
                    onSelect: { option in select(option, for: item) }
                )
            }
        }
        .zIndex(expandedItemID == item.id ? 10 : 0)
        .opacity(isCoveredByExpandedSibling ? 0 : 1)
        .allowsHitTesting(!isCoveredByExpandedSibling)
        .accessibilityHidden(isCoveredByExpandedSibling)
        // 测量 capsule 在 settingsGrid 坐标系下的真实 frame，排查 LIVE 是否 width=0 或被挤没
        .measureItemFrame(rowIndex: rowIndex, itemID: item.id)
        .onAppear {
            TestLog.log(
                "capsuleState row=\(rowIndex) id=\(item.id) title=\(item.title) component=\(componentName) rowItemCount=\(rowItemCount) expandedID=\(expandedItemID ?? "nil") expandedInRow=\(expandedIDInRow ?? "nil") covered=\(isCoveredByExpandedSibling) opacity=\(isCoveredByExpandedSibling ? 0 : 1) zIndex=\(expandedItemID == item.id ? 10 : 0)"
            )
        }
        .onChange(of: expandedItemID) { newValue in
            guard rowIndex == 1 || item.id == "live" || item.id == "grid" else { return }
            let expandedInRow = Self.rows[rowIndex].first { $0.id == newValue }?.id
            let covered = expandedInRow != nil && expandedInRow != item.id
            TestLog.log(
                "capsuleState expandedIDChanged row=\(rowIndex) id=\(item.id) expandedID=\(newValue ?? "nil") expandedInRow=\(expandedInRow ?? "nil") covered=\(covered) opacity=\(covered ? 0 : 1)"
            )
        }
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

    private func handleTap(_ item: SettingItem) {
        TestLog.log(
            "handleTap id=\(item.id), title=\(item.title), kind=\(debugKindDescription(item.kind)), position=\(debugPositionDescription(item.position)), expandedBefore=\(expandedItemID ?? "nil"), rowOrder=\(debugRowDescription(containing: item)), selected=\(optionSelections[item.id] ?? "nil"), toggles=\(debugToggleDescription())"
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
            "select option=\(option), id=\(item.id), previous=\(optionSelections[item.id] ?? "nil"), expandedBefore=\(expandedItemID ?? "nil")"
        )

        optionSelections[item.id] = option
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

    /// 输出网格 item 的真实布局 frame；默认重点打印第二行（LIVE / 网格 / 水平仪）
    private func logItemFrames(_ frames: [ItemFrameDebugInfo]) {
        let sortedFrames = frames.sorted {
            if $0.rowIndex != $1.rowIndex { return $0.rowIndex < $1.rowIndex }
            return $0.itemID < $1.itemID
        }

        for info in sortedFrames where info.rowIndex == 1 {
            TestLog.log(
                "itemFrame row=\(info.rowIndex) id=\(info.itemID) minX=\(debugNumber(info.frame.minX)) minY=\(debugNumber(info.frame.minY)) width=\(debugNumber(info.frame.width)) height=\(debugNumber(info.frame.height)) maxX=\(debugNumber(info.frame.maxX))"
            )
        }
    }
}

// MARK: - 高度测量（PreferenceKey 方案）

struct ItemFrameDebugInfo: Equatable {
    let rowIndex: Int
    let itemID: String
    let frame: CGRect
}

struct ItemFramePreferenceKey: PreferenceKey {
    static var defaultValue: [ItemFrameDebugInfo] = []

    static func reduce(value: inout [ItemFrameDebugInfo], nextValue: () -> [ItemFrameDebugInfo]) {
        value.append(contentsOf: nextValue())
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// 用 GeometryReader 测量 item 在 settingsGrid 坐标系下的 frame，用于排查布局被挤没/覆盖
    func measureItemFrame(rowIndex: Int, itemID: String) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ItemFramePreferenceKey.self,
                    value: [
                        ItemFrameDebugInfo(
                            rowIndex: rowIndex,
                            itemID: itemID,
                            frame: proxy.frame(in: .named("settingsGrid"))
                        ),
                    ]
                )
            }
        )
    }

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
