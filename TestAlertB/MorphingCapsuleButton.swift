//
//  MorphingCapsuleButton.swift
//  TestAlertB
//
//  支持“原地形变”的胶囊按钮组件 + 数据模型
//

import SwiftUI

// MARK: - 数据模型

/// 按钮在行内的位置，决定胶囊展开时的锚点方向
/// 左侧按钮锚点在左向右伸展，右侧相反，居中向两侧对称伸展（防止超出屏幕边缘）
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

/// 按钮类型：开关型（点击切换） / 选项型（点击原地展开为分段胶囊）
enum SettingItemKind {
    case toggle
    case options([String])
}

 //MARK: - 数据模型
struct SettingItem: Identifiable {
    /// 使用稳定的字符串 id（而非 UUID()），保证视图重建后展开/选中状态不丢失
    let id: String
    let icon: String
    let title: String
    let kind: SettingItemKind
    let position: ButtonPosition
}

/// 主题色：选中高亮的荧光黄绿
enum CapsuleTheme {
    static let accent = Color(red: 0.84, green: 0.95, blue: 0.29)
}

// MARK: - 形变胶囊按钮

struct MorphingCapsuleButton: View {
    let item: SettingItem
    /// 当前行内的按钮数量，用于计算展开后与网格行对齐的总宽度
    let rowItemCount: Int
    let isExpanded: Bool
    let isOn: Bool
    let selectedOption: String?
    let onTap: () -> Void
    let onSelect: (String) -> Void

    private let buttonHeight: CGFloat = 60
    private let cornerRadius: CGFloat = 20
    private let selectionCornerRadius: CGFloat = 14
    private let rowSpacing: CGFloat = 12

    private var options: [String] {
        if case .options(let opts) = item.kind { return opts }
        return []
    }

    /// 展开后与下方网格整行对齐的总宽度
    private func rowWidth(slotWidth: CGFloat) -> CGFloat {
        slotWidth * CGFloat(rowItemCount) + rowSpacing * CGFloat(rowItemCount - 1)
    }

    var body: some View {
        // GeometryReader 只负责提供当前格子的宽度（slotWidth）。
        // 形变主体可以超出格子宽度绘制，但不参与 HStack 布局计算，
        // 因此展开时不会挤压相邻的兄弟按钮。
        GeometryReader { geo in
            let slotWidth = geo.size.width

            morphingBody(slotWidth: slotWidth)
                // 按 position 锚定：内容超宽时从锚点方向溢出
                .frame(width: slotWidth, height: buttonHeight, alignment: item.position.anchor)
                .onAppear {
                    logLayout(
                        slotWidth: slotWidth,
                        reason: "appear",
                        expandedValue: isExpanded,
                        selectedValue: selectedOption
                    )
                }
                .onChange(of: isExpanded) { newValue in
                    logLayout(
                        slotWidth: slotWidth,
                        reason: "isExpandedChanged=\(newValue)",
                        expandedValue: newValue,
                        selectedValue: selectedOption
                    )
                }
                .onChange(of: selectedOption) { newValue in
                    logLayout(
                        slotWidth: slotWidth,
                        reason: "selectedOptionChanged=\(newValue ?? "nil")",
                        expandedValue: isExpanded,
                        selectedValue: newValue
                    )
                }
        }
        .frame(height: buttonHeight)
        // 展开瞬间提升 Z 层级，保证覆盖在相邻按钮之上
        .zIndex(isExpanded ? 10 : 0)
    }

    private func morphingBody(slotWidth: CGFloat) -> some View {
        ZStack {
            buttonBackground

            collapsedLabel
                .opacity(isExpanded ? 0 : 1)

            if !options.isEmpty {
                optionSegments
                    .opacity(isExpanded ? 1 : 0)
                    .allowsHitTesting(isExpanded)
            }
        }
        .frame(width: isExpanded ? rowWidth(slotWidth: slotWidth) : slotWidth, height: buttonHeight)
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onTapGesture {
            TestLog.log(
                "tap id=\(item.id), title=\(item.title), isExpandedBefore=\(isExpanded), selected=\(selectedOption ?? "nil")"
            )
            if !isExpanded { onTap() }
        }
    }

    @ViewBuilder
    private var buttonBackground: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        switch item.id {
        case "ratio":
            shape.fill(Color.green)
        case "timer":
            shape.fill(Color.red)
        default:
            shape
                .fill(.regularMaterial)
                .environment(\.colorScheme, .dark)
        }
    }

    private var collapsedLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: item.icon)
                .font(.system(size: 18, weight: .medium))
            Text(item.title)
                .font(.system(size: 15, weight: .medium))
        }
        .foregroundStyle(isOn ? CapsuleTheme.accent : .white)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private var optionSegments: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
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
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
    }

    private func logLayout(
        slotWidth: CGFloat,
        reason: String,
        expandedValue: Bool,
        selectedValue: String?
    ) {
        let visibleWidth = expandedValue ? rowWidth(slotWidth: slotWidth) : slotWidth

        TestLog.log(
            "layout reason=\(reason), id=\(item.id), title=\(item.title), position=\(debugPositionDescription(item.position)), rowItemCount=\(rowItemCount), loggedExpanded=\(expandedValue), selected=\(selectedValue ?? "nil"), slotWidth=\(debugNumber(slotWidth)), visibleWidth=\(debugNumber(visibleWidth)), viewZIndex=\(expandedValue ? 10 : 0)"
        )
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

    private func debugNumber(_ value: CGFloat) -> String {
        let rounded = (Double(value) * 10).rounded() / 10
        return "\(rounded)"
    }
}
