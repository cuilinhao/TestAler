//
//  CaptureParameterPanel.swift
//  TestAlertB
//
//  通用顶部参数面板：外壳样式、行布局、选中态、禁用态、Slider 行
//  业务数据由 VideoParameterPanel / TimerParameterPanel 组装后传入
//

import SwiftUI

// MARK: - 设计 Token

/// 面板视觉常量，与截图对齐；宽度仍由父布局推导，不写死面板总宽
enum CaptureParameterPanelStyle {
    static let backgroundColor = Color(red: 0.01, green: 0.09, blue: 0.11).opacity(0.92)
    static let accent = Color(red: 0.83, green: 1.0, blue: 0.35)
    static let disabledText = Color.white.opacity(0.35)
    static let sliderTrack = Color(red: 0.45, green: 0.42, blue: 0.28).opacity(0.55)

    static let bottomCornerRadius: CGFloat = 44
    static let horizontalPadding: CGFloat = 38
    static let topPadding: CGFloat = 34
    static let bottomPadding: CGFloat = 34
    static let rowSpacing: CGFloat = 26
    /// 左侧标题列宽，保证各行选项区垂直对齐
    static let titleColumnWidth: CGFloat = 112
    static let optionRowSpacing: CGFloat = 24
    static let optionFontSize: CGFloat = 16
    static let titleFontSize: CGFloat = 16
    static let noteFontSize: CGFloat = 13
    /// inline 布局时选项之间的水平间距
    static let inlineOptionSpacing: CGFloat = 40
}

// MARK: - 面板容器

/// 通用参数面板外壳 + 多行内容；只负责渲染，不持有业务状态
struct CaptureParameterPanel: View {
    let rows: [ParameterRow]

    var body: some View {
        VStack(alignment: .leading, spacing: CaptureParameterPanelStyle.rowSpacing) {
            ForEach(rows) { row in
                ParameterRowView(row: row)
            }
        }
        .padding(.horizontal, CaptureParameterPanelStyle.horizontalPadding)
        .padding(.top, CaptureParameterPanelStyle.topPadding)
        .padding(.bottom, CaptureParameterPanelStyle.bottomPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CaptureParameterPanelStyle.backgroundColor)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: CaptureParameterPanelStyle.bottomCornerRadius,
                bottomTrailingRadius: CaptureParameterPanelStyle.bottomCornerRadius,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - 行路由

/// 按 ParameterRow 类型分发到 options 行或 slider 行
private struct ParameterRowView: View {
    let row: ParameterRow

    var body: some View {
        switch row {
        case .options(_, let title, let options, let selection, let layout, let trailingNote):
            ParameterOptionsRowView(
                title: title,
                options: options,
                selection: selection,
                layout: layout,
                trailingNote: trailingNote
            )
        case .slider(_, let title, let value, let range, let trailingText):
            ParameterSliderRowView(
                title: title,
                value: value,
                range: range,
                trailingText: trailingText
            )
        }
    }
}

// MARK: - Options 行

/// 左侧标题 + 右侧选项区（grid 两列 / inline 单行）
private struct ParameterOptionsRowView: View {
    let title: String
    let options: [ParameterOption]
    @Binding var selection: String
    let layout: ParameterOptionsLayout
    let trailingNote: String?

    private let columns = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible(), alignment: .leading),
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(title)
                .font(.system(size: CaptureParameterPanelStyle.titleFontSize, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: CaptureParameterPanelStyle.titleColumnWidth, alignment: .leading)

            optionsContent
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var optionsContent: some View {
        switch layout {
        case .grid:
            LazyVGrid(
                columns: columns,
                alignment: .leading,
                spacing: CaptureParameterPanelStyle.optionRowSpacing
            ) {
                ForEach(options) { option in
                    optionButton(for: option)
                }
            }
        case .inline:
            HStack(alignment: .firstTextBaseline, spacing: CaptureParameterPanelStyle.inlineOptionSpacing) {
                ForEach(options) { option in
                    optionButton(for: option)
                }

                if let trailingNote {
                    Text(trailingNote)
                        .font(.system(size: CaptureParameterPanelStyle.noteFontSize, weight: .regular))
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func optionButton(for option: ParameterOption) -> some View {
        ParameterOptionView(
            option: option,
            isSelected: selection == option.id,
            onSelect: {
                guard option.isEnabled else { return }
                selection = option.id
            }
        )
    }
}

// MARK: - 单个选项

/// 选中态：黄绿三角 + 文字 + 下划线；禁用态：灰色 + 可选锁图标
private struct ParameterOptionView: View {
    let option: ParameterOption
    let isSelected: Bool
    let onSelect: () -> Void

    private var textColor: Color {
        if !option.isEnabled {
            return CaptureParameterPanelStyle.disabledText
        }
        return isSelected ? CaptureParameterPanelStyle.accent : .white
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 3) {
                // 选中三角；未选中留同等占位，避免列内文字跳动
                Group {
                    if isSelected {
                        Image(systemName: "play.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(CaptureParameterPanelStyle.accent)
                    } else {
                        Color.clear
                            .frame(width: 7, height: 7)
                    }
                }
                .frame(width: 9, alignment: .leading)

                if !option.isEnabled, option.showsLockWhenDisabled {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CaptureParameterPanelStyle.disabledText)
                }

                Text(option.title)
                    .font(.system(size: CaptureParameterPanelStyle.optionFontSize, weight: .regular))
                    .foregroundStyle(textColor)
                    .overlay(alignment: .bottom) {
                        if isSelected {
                            Rectangle()
                                .fill(CaptureParameterPanelStyle.accent)
                                .frame(height: 1)
                                .offset(y: 3)
                        }
                    }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!option.isEnabled)
    }
}

// MARK: - Slider 行

/// 拍摄时长：左侧标题 + 中间 Slider + 右侧固定文案（180s）
private struct ParameterSliderRowView: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let trailingText: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.system(size: CaptureParameterPanelStyle.titleFontSize, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: CaptureParameterPanelStyle.titleColumnWidth, alignment: .leading)

            Slider(value: $value, in: range)
                .tint(CaptureParameterPanelStyle.sliderTrack)

            Text(trailingText)
                .font(.system(size: CaptureParameterPanelStyle.optionFontSize, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .frame(minWidth: 36, alignment: .trailing)
        }
    }
}
