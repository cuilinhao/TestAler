//
//  CapsuleCollapsedContent.swift
//  TestAlertB
//
//  胶囊收起态 UI：按 CollapsedStyle 解耦，Sheet / 胶囊组件不写业务 if
//

import SwiftUI

// MARK: - 路由

struct CapsuleCollapsedContentView: View {
    let style: CameraSettings.CollapsedStyle
    let selectedOption: String?
    let isOn: Bool

    var body: some View {
        Group {
            switch style {
            case .valueBadge(let title):
                ValueBadgeCollapsedView(
                    value: selectedOption ?? CameraSettings.AspectRatio.defaultValue.rawValue,
                    title: title
                )
            case .countdownIndicator(let title):
                CountdownCollapsedView(
                    countdown: CameraSettings.Countdown(selection: selectedOption) ?? .off,
                    title: title
                )
            case .toggleIcon(let systemName, let title):
                ToggleIconCollapsedView(systemName: systemName, title: title, isOn: isOn)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 比例：左侧值 badge + 右侧标题

struct ValueBadgeCollapsedView: View {
    let value: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - 倒计时：左侧动态指示 + 右侧标题

struct CountdownCollapsedView: View {
    let countdown: CameraSettings.Countdown
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

    @ViewBuilder
    private var leadingIndicator: some View {
        switch countdown.leading {
        case .slashTimer:
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

// MARK: - 开关 / 功能项：icon + 标题（ON 态配色由外层胶囊背景负责）

struct ToggleIconCollapsedView: View {
    let systemName: String
    let title: String
    let isOn: Bool

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

// MARK: - 胶囊背景（toggle ON：黄底 + 蓝描边）

struct CapsuleChromeBackground: View {
    let cornerRadius: CGFloat
    let usesToggleOnChrome: Bool

    var body: some View {
        Group {
            if usesToggleOnChrome {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(CapsuleTheme.accent)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(CapsuleTheme.onBorder, lineWidth: 2)
                    }
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .environment(\.colorScheme, .dark)
            }
        }
    }
}
