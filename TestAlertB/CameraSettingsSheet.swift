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

    /// 顶部拖拽指示条区域的固定高度（参与 Sheet 总高度计算）
    private let grabberZoneHeight: CGFloat = 32

    /// 多行不等列布局：2 / 3 / 3 / 2，每行内部平分宽度
    private static let rows: [[SettingItem]] = [
        [
            .init(id: "ratio", icon: "aspectratio", title: "比例", kind: .options(["1:1", "4:3", "16:9"]), position: .left),
            .init(id: "timer", icon: "timer", title: "倒计时", kind: .options(["关闭", "3秒", "10秒"]), position: .right),
        ],
        [
            .init(id: "live", icon: "livephoto.slash", title: "LIVE", kind: .toggle, position: .left),
            .init(id: "grid", icon: "grid", title: "网格", kind: .toggle, position: .center),
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
    ]

    var body: some View {
        GeometryReader { screen in
            // 边界阈值：屏幕高度的 60%
            let maxSheetHeight = screen.size.height * 0.6
            // 内容真实高度超过阈值 -> 锁定 60% 并启用内部滚动
            let needsScroll = contentHeight + grabberZoneHeight > maxSheetHeight

            ZStack(alignment: .bottom) {
                if isPresented {
                    // 暗色遮罩：点击面板外部区域自动收回
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { dismiss() }
                        .transition(.opacity)

                    sheetPanel(maxHeight: maxSheetHeight, needsScroll: needsScroll)
                        .transition(.move(edge: .bottom))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isPresented)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: expandedItemID)
    }

    // MARK: - 面板主体

    private func sheetPanel(maxHeight: CGFloat, needsScroll: Bool) -> some View {
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
        .onTapGesture { collapseExpanded() }
        .offset(y: max(dragOffset, 0))
        .gesture(dragToDismiss)
    }

    private var settingsGrid: some View {
        VStack(spacing: 12) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 12) {
                    ForEach(row) { item in
                        MorphingCapsuleButton(
                            item: item,
                            rowItemCount: row.count,
                            isExpanded: expandedItemID == item.id,
                            isOn: enabledToggles.contains(item.id),
                            selectedOption: optionSelections[item.id],
                            onTap: { handleTap(item) },
                            onSelect: { option in select(option, for: item) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        // PreferenceKey 方案测量内容真实高度，驱动 Sheet 高度自适应
        .measureHeight($contentHeight)
    }

    // MARK: - 手势

    private var dragToDismiss: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                if value.translation.height > 100 {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - 状态流转

    private func handleTap(_ item: SettingItem) {
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
    }

    private func select(_ option: String, for item: SettingItem) {
        optionSelections[item.id] = option
        // 选择后延迟 0.2 秒，胶囊原路收缩回普通按钮
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                expandedItemID = nil
            }
        }
    }

    private func collapseExpanded() {
        guard expandedItemID != nil else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            expandedItemID = nil
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            expandedItemID = nil
            isPresented = false
            dragOffset = 0
        }
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
            height.wrappedValue = newHeight
        }
    }
}
