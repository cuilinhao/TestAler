//
//  MultipleCapsuleButton.swift
//  TestAlertB
//
//  多选项形变胶囊：锚点/宽度逻辑与 MorphingCapsuleButton 一致，展开后横向滑动 + 边缘渐淡
//

import SwiftUI

// MARK: - 多选项形变胶囊按钮

struct MultipleCapsuleButton: View {
    let item: SettingItem
    /// 行内等分列数（小格 3 / 大格 2），用于计算展开后的整行宽度
    let columnCount: Int
    /// 由行内 index 推导的展开锚点
    let position: ButtonPosition
    /// 是否处于展开态，由父级 expandedItemID 推导，子组件不自行维护
    let isExpanded: Bool
    /// toggle 型 item 的开关状态；options 型 item 目前不参与收起态配色
    let isOn: Bool
    /// 当前选中的 option 文案，由父级 optionSelections 传入
    let selectedOption: String?
    let isTapEnabled: Bool
    /// 点击收起态胶囊时回调，父级负责设置 expandedItemID
    let onTap: () -> Void
    /// 点击某个 option 时回调，父级负责写入选中值并在 0.2s 后收回
    let onSelect: (String) -> Void

    // 设计 token：允许写死的高度、圆角、间距；横向宽度必须从布局推导
    private let buttonHeight: CGFloat = 60
    private let cornerRadius: CGFloat = 20
    /// 选中高亮块的内圆角，略小于外层胶囊
    private let selectionCornerRadius: CGFloat = 14
    /// 与 CameraSettingsSheet 网格 HStack spacing 保持一致
    private let rowSpacing: CGFloat = 12
    /// 一屏大约展示 4 个 option，用于推导单个 cell 宽度（非绝对 pt）
    private let visibleOptionCount: CGFloat = 4.0
    /// 边缘 option 的最低透明度，文字不会被裁切，只是变淡
    private let minOptionOpacity: Double = 0.3
    /// 渐淡强度：边缘 progress=1 时 opacity = 1 - fadeStrength = 0.3
    private let fadeStrength: Double = 0.7

    /// 从 item.kind 中取出 options 数组；非 options 型返回空
    private var options: [String] {
        if case .options(let opts) = item.kind { return opts }
        return []
    }

    /// 展开后与当前网格行等宽：slotWidth × 列数 + 列间距 × (列数 - 1)
    private func rowWidth(slotWidth: CGFloat) -> CGFloat {
        slotWidth * CGFloat(columnCount) + rowSpacing * CGFloat(columnCount - 1)
    }

    var body: some View {
        // GeometryReader 只负责提供当前格子的宽度（slotWidth）。
        // 形变主体可以超出格子宽度绘制，但不参与 HStack 布局计算，
        // 因此展开时不会挤压相邻的兄弟按钮。
        GeometryReader { geo in
            // 当前 item 在网格中分到的格子宽度
            let slotWidth = geo.size.width

            morphingBody(slotWidth: slotWidth)
                // 按 position 锚定：内容超宽时从锚点方向溢出（左→右展，右→左展，中→对称展）
                .frame(width: slotWidth, height: buttonHeight, alignment: position.anchor)
        }
        .frame(height: buttonHeight)
        // 展开瞬间提升 Z 层级，保证覆盖在相邻按钮之上
        .zIndex(isExpanded ? 10 : 0)
    }

    /// 形变主体：收起态显示 icon+title，展开态显示可横向滑动的 option 列表
    private var usesToggleOnChrome: Bool {
        !isExpanded && isOn && item.collapsedStyle.isToggleIcon
    }

    @ViewBuilder
    private func morphingBody(slotWidth: CGFloat) -> some View {
        // 展开后胶囊的可见宽度 = 当前行整行宽度
        let expandedWidth = rowWidth(slotWidth: slotWidth)
        // 形变体外层实际 frame 宽度：收起 = slotWidth，展开 = expandedWidth
        let morphFrameWidth = isExpanded ? expandedWidth : slotWidth

        ZStack {
            CapsuleChromeBackground(cornerRadius: cornerRadius, usesToggleOnChrome: usesToggleOnChrome)

            CapsuleCollapsedContentView(
                style: item.collapsedStyle,
                selectedOption: selectedOption,
                isOn: isOn
            )
            .opacity(isExpanded ? 0 : 1)

            // 仅展开态挂载 ScrollView，避免收起态整行宽透明层盖住同行兄弟（如 LIVE）
            if isExpanded, !options.isEmpty {
                scrollableOptions(expandedWidth: expandedWidth)
            }
        }
        // 形变宽度：收起 = slotWidth，展开 = expandedWidth
        .frame(width: morphFrameWidth, height: buttonHeight)
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onTapGesture {
            if !isExpanded && isTapEnabled { onTap() }
        }
    }

    /// 展开态横向 option 区域：固定外层宽度为 expandedWidth，内容可超出并滑动
    private func scrollableOptions(expandedWidth: CGFloat) -> some View {
        // 单个 option 宽度 = 展开宽度 / 可见数量比例，6 个 option 总宽 > expandedWidth 时可滑动
        let optionCellWidth = expandedWidth / visibleOptionCount

        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        optionCell(
                            option: option,
                            cellWidth: optionCellWidth,
                            viewportWidth: expandedWidth
                        )
                        // 供 scrollTo 定位到当前选中项
                        .id(option)
                    }
                }
                // 与 MorphingCapsuleButton optionSegments 左右内边距一致
                .padding(.horizontal, 6)
            }
            // 命名坐标系：option 渐淡计算都相对于胶囊可见区域
            .coordinateSpace(name: "capsuleViewport")
            // 滚动区域宽度锁死为 expandedWidth，不会随 option 数量撑宽外层
            .frame(width: expandedWidth, height: buttonHeight)
            .onAppear {
                scrollToSelected(using: proxy)
            }
            .onChange(of: isExpanded) { expanded in
                if expanded {
                    scrollToSelected(using: proxy)
                }
            }
        }
    }

    /// 单个 option cell：荧光黄绿选中高亮 + 随位置变化的边缘渐淡
    private func optionCell(option: String, cellWidth: CGFloat, viewportWidth: CGFloat) -> some View {
        Button {
            onSelect(option)
        } label: {
            GeometryReader { geo in
                // option 中心点在胶囊可见区域中的 X 坐标
                let midX = geo.frame(in: .named("capsuleViewport")).midX
                // 越靠近胶囊中心 opacity 越高，越靠近左右边缘越淡
                let opacity = edgeFadeOpacity(midX: midX, viewportWidth: viewportWidth)

                Text(option)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(option == selectedOption ? .black : .white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if option == selectedOption {
                            RoundedRectangle(cornerRadius: selectionCornerRadius, style: .continuous)
                                .fill(CapsuleTheme.accent)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 6)
                        }
                    }
                    .opacity(opacity)
            }
        }
        .buttonStyle(.plain)
        .frame(width: cellWidth, height: buttonHeight)
    }

    /// 根据 option 中心与胶囊中心的距离计算透明度，不使用 mask 硬裁切文字
    private func edgeFadeOpacity(midX: CGFloat, viewportWidth: CGFloat) -> Double {
        // 胶囊可见区域的中心 X
        let capsuleCenterX = viewportWidth / 2
        // option 中心偏离胶囊中心的距离
        let distance = abs(midX - capsuleCenterX)
        // 归一化到 [0, 1]：中心为 0，左右边缘为 1
        let progress = distance / (viewportWidth / 2)
        // 线性渐淡：中心 opacity=1，边缘 opacity=1-fadeStrength=0.3
        let opacity = 1 - progress * fadeStrength
        return max(minOptionOpacity, opacity)
    }

    /// 展开后将当前选中 option 滚动到胶囊中心
    private func scrollToSelected(using proxy: ScrollViewProxy) {
        guard let selected = selectedOption else { return }

        // 延迟到下一 runloop，确保 ScrollView 完成布局后再 scrollTo
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(selected, anchor: .center)
            }
        }
    }
}
