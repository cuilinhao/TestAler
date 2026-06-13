//
//  CapsuleCollapsedContent.swift
//  TestAlertB
//
//  胶囊收起态 UI：按 CollapsedStyle 解耦，Sheet / 胶囊组件不写业务 if
//

import SwiftUI

// MARK: - 路由

/// 收起态内容路由器：根据 CollapsedStyle 选择对应子 View
struct CapsuleCollapsedContentView: View {
    let style: CameraSettings.CollapsedStyle
    /// 当前选中 option 文案（比例 badge 等）；倒计时运行态不读此字段
    let selectedOption: String?
    /// toggle 是否 ON；决定 icon/文字颜色及外层是否使用黄底
    let isOn: Bool
    /// 倒计时进行中剩余秒数；nil 表示关闭态（斜杠 timer）
    let countdownRemainingSeconds: Int?

    var body: some View {
        Group {
            switch style {
            case .valueBadge(let title):
                ValueBadgeCollapsedView(
                    value: selectedOption ?? CameraSettings.AspectRatio.defaultValue.rawValue,
                    title: title
                )
            case .optionalValueBadge(let offSystemName, let title):
                OptionalValueBadgeCollapsedView(
                    value: selectedOption,
                    offSystemName: offSystemName,
                    title: title
                )
            case .countdownIndicator(let title):
                CountdownCollapsedView(
                    remainingSeconds: countdownRemainingSeconds,
                    title: title
                )
            case .toggleIcon(let offSystemName, let onSystemName, let title):
                ToggleIconCollapsedView(
                    offSystemName: offSystemName,
                    onSystemName: onSystemName,
                    title: title,
                    isOn: isOn
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 比例：左侧值 badge + 右侧标题

/// 比例收起态：[ 4:3 ] + 「比例」
struct ValueBadgeCollapsedView: View {
    let value: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            // 左侧：当前选中比例，白字描边 capsule
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                }

            // 右侧：固定标题
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - 可选值：未选择显示 icon，选择后显示值

/// Log还原 / 防抖：没选过时保持 icon+标题，选过后才展示当前选中值
struct OptionalValueBadgeCollapsedView: View {
    ///胶囊中选中的值
    let value: String?
    
    let offSystemName: String
    /// 初始的title
    let title: String

    var body: some View {
        if let value, !value.isEmpty {
            
            ValueBadgeCollapsedView(value: value, title: title)
                .onAppear {
                    debugPrint("++++logo value \(value), title:\(title)")
                }
            
        } else {
            ToggleIconCollapsedView(
                offSystemName: offSystemName,
                onSystemName: offSystemName,
                title: title,
                isOn: false
            )
        }
    }
        
}

// MARK: - 倒计时：左侧动态指示 + 右侧标题

/// 倒计时收起态：关闭 = 斜杠 timer；运行中 = 圆 badge 递减秒数
struct CountdownCollapsedView: View {
    /// 运行中剩余秒数；nil 或 ≤0 时显示关闭态
    let remainingSeconds: Int?
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            leadingIndicator
                .frame(width: 28, height: 28)

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
    }

    /// 根据 remainingSeconds 推导左侧指示类型
    private var leading: CameraSettings.Countdown.Leading {
        if let remainingSeconds, remainingSeconds > 0 {
            return .seconds(remainingSeconds)
        }
        return .slashTimer
    }

    @ViewBuilder
    private var leadingIndicator: some View {
        switch leading {
        case .slashTimer:
            //  默认态：timer + 斜杠
            Image(systemName: "timer")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
                .overlay(alignment: .center) {
                    Image(systemName: "line.diagonal")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-45))
                }
        case .seconds(let value):
            // 运行中：圆 badge 显示当前剩余秒数
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                Text("\(value)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - 开关 / 功能项：icon + 标题

/// toggle 收起态：OFF 白字；ON 黑字（黄底由 CapsuleChromeBackground 提供）
struct ToggleIconCollapsedView: View {
    let offSystemName: String
    let onSystemName: String
    let title: String
    let isOn: Bool

    /// 按开关态选择 SF Symbol；LIVE 等 item 的 ON/OFF icon 不同
    private var systemName: String {
        isOn ? onSystemName : offSystemName
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(isOn ? .black : .white)
        .padding(.horizontal, 4)
    }
}

// MARK: - 胶囊背景

/// 胶囊外层背景：默认毛玻璃；toggle ON 时为荧光黄绿纯色底（无描边）
struct CapsuleChromeBackground: View {
    let cornerRadius: CGFloat
    /// 是否使用 toggle ON 态黄底
    let usesToggleOnChrome: Bool

    var body: some View {
        Group {
            if usesToggleOnChrome {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(CapsuleTheme.accent)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .environment(\.colorScheme, .dark)
            }
        }
    }
}
