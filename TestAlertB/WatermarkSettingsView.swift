//
//  WatermarkSettingsView.swift
//  TestAlertB
//
//  水印设置子页：Push 进入，Pop 返回主设置网格
//

import SwiftUI

/// 水印模板占位数据
private struct WatermarkTemplate: Identifiable {
    let id: Int
    let brandIcon: String
    let deviceName: String
    let cameraInfo: String
}

struct WatermarkSettingsView: View {
    @Binding var isEnabled: Bool
    @Binding var selectedIndex: Int
    var onBack: () -> Void

    private let maxCardWidth: CGFloat = 280
    private let cardCornerRadius: CGFloat = 8
    private let infoBarHeight: CGFloat = 34
    private let horizontalPadding: CGFloat = 16
    private let cardSpacing: CGFloat = 16
    private let nextCardPeekWidth: CGFloat = 36

    /// 根据屏幕宽度收窄卡片，保证右侧能露出下一张卡片边缘
    private var cardWidth: CGFloat {
        let availableWidth = UIScreen.main.bounds.width - horizontalPadding * 2 - nextCardPeekWidth
        return min(maxCardWidth, max(230, availableWidth))
    }

    // 占位模板
    private let templates: [WatermarkTemplate] = [
        .init(id: 0, brandIcon: "applelogo", deviceName: "iPhone 17 Pro Max", cameraInfo: "50mm f/1.78 1/80s ISO 640"),
        .init(id: 1, brandIcon: "sun.max.fill", deviceName: "iPhone 17 Pro Max", cameraInfo: "50mm f/1.78 1/80s ISO 640"),
        .init(id: 2, brandIcon: "applelogo", deviceName: "iPhone 17 Pro Max", cameraInfo: "50mm f/1.78 1/80s ISO 640"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            cardList
        }
        .padding(.bottom, 24)
    }

    // MARK: - 自定义顶栏（非系统 NavigationBar）

    private var navigationBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                    Text("水印")
                        .font(.system(size: 17, weight: .regular))
                }
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(CapsuleTheme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }

    // MARK: - 横向卡片列表

    private var cardList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: cardSpacing) {
                ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                    watermarkCard(template: template, index: index)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 15) /// 调节上下距离
        }
    }

    private func watermarkCard(template: WatermarkTemplate, index: Int) -> some View {
        let isSelected = selectedIndex == index
        let previewHeight = cardWidth * 9 / 16 - infoBarHeight

        return Button {
            selectedIndex = index
        } label: {
            VStack(spacing: 0) {
                // 上半：预览图占位（雪山渐变）
                watermarkPreview
                    .frame(width: cardWidth, height: previewHeight)
                    .clipped()

                // 下半：白色信息栏
                HStack(spacing: 6) {
                    Image(systemName: template.brandIcon)
                        .font(.system(size: 11, weight: .medium))
                    Text(template.deviceName)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(template.cameraInfo)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .frame(width: cardWidth, height: infoBarHeight)
                .background(Color.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
            .overlay {
                if isSelected {
                    // 选中态：青柠色描边
                    RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                        .stroke(CapsuleTheme.accent, lineWidth: 2.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// 预览占位图：灰色山脉渐变，后续可换 Asset
    private var watermarkPreview: some View {
        LinearGradient(
            colors: [
                Color(white: 0.55),
                Color(white: 0.72),
                Color(white: 0.85),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .bottom) {
            Image(systemName: "mountain.2.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 24)
                .offset(y: 12)
        }
    }
}
