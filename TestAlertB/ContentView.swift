//
//  ContentView.swift
//  TestAlertB
//
//  主界面：模拟相机预览背景 + 按钮 A，点击弹出底部设置面板（弹框 B）
//  主界面：绿色预览 + 顶部工具栏 + 参数面板（HEIF / Timer / Photo）
//

import SwiftUI

struct ContentView: View {
    /// HEIF 按钮展示文案（顶部胶囊标签）
    @State private var selectedCaptureFormat: CaptureFormat = .heif
    /// 单一枚举管理面板互斥，避免 video / timer 同时为 true
    @State private var activeParameterPanel: ActiveParameterPanel?

    // 截图 1：录像参数状态（面板关闭后仍保留）
    @State private var colorSpace = "SDR"
    @State private var codec = "ProRes Proxy"
    @State private var resolution = "FHD"
    @State private var frameRate = "24"

    // 截图 2：间隔拍摄参数状态
    @State private var captureInterval = "1s"
    @State private var captureDurationSeconds = 0.0
    @State private var timerResolution = "FHD"

    // 拍照参数状态
    @State private var photoFormat = "HEIF"
    @State private var photoResolution = "48MP"

    var body: some View {
        VStack(spacing: 0) {
            FeaturesToolbar(
                selectedFormat: selectedCaptureFormat,
                onFormatTap: { togglePanel(.video) },
                onTimerTap: { togglePanel(.timer) },
                onPhotoTap: { togglePanel(.photo) }
            )
            .frame(maxWidth: .infinity)
            .frame(height: 40)

            ZStack(alignment: .top) {
                GreenPreviewPlaceholder()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(3 / 4.0, contentMode: .fit)
                    .onTapGesture {
                        hideParameterPanel()
                    }

                if let panel = activeParameterPanel {
                    parameterPanel(for: panel)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .zIndex(1)
                }
            }
            .layoutPriority(100)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
    }

    // MARK: - 面板切换

    /// 再次点击同一按钮则收起；点击另一按钮则切换内容
    private func togglePanel(_ panel: ActiveParameterPanel) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            if activeParameterPanel == panel {
                activeParameterPanel = nil
            } else {
                activeParameterPanel = panel
            }
        }
    }

    private func hideParameterPanel() {
        guard activeParameterPanel != nil else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            activeParameterPanel = nil
        }
    }

    /// 按激活类型渲染对应业务包装 View
    @ViewBuilder
    private func parameterPanel(for panel: ActiveParameterPanel) -> some View {
        switch panel {
        case .video:
            VideoParameterPanel(
                colorSpace: $colorSpace,
                codec: $codec,
                resolution: $resolution,
                frameRate: $frameRate
            )
        case .timer:
            TimerParameterPanel(
                captureInterval: $captureInterval,
                captureDurationSeconds: $captureDurationSeconds,
                timerResolution: $timerResolution
            )
        case .photo:
            PhotoParameterPanel(
                photoFormat: $photoFormat,
                photoResolution: $photoResolution
            )
        }
    }
}

// MARK: - 顶部工具栏

struct FeaturesToolbar: View {
    let selectedFormat: CaptureFormat
    let onFormatTap: () -> Void
    let onTimerTap: () -> Void
    let onPhotoTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CaptureParamButton(format: selectedFormat, action: onFormatTap)
                .background(Capsule().fill(.secondary))

            Button(action: onTimerTap) {
                Text("Timer")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(height: 30)
                    .padding(.horizontal, 10)
            }
            .background(Capsule().fill(.secondary))

            Button(action: onPhotoTap) {
                Text("Photo")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(height: 30)
                    .padding(.horizontal, 10)
            }
            .background(Capsule().fill(.secondary))

            Spacer()

            Button(action: popCaptureModeSetting) {
                Image(systemName: "ellipsis.bubble")
                    .contentShape(.rect)
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.white)
            }
            .background(Circle().fill(.secondary))

            Button(action: popSetting) {
                Image(systemName: "gearshape")
                    .contentShape(.rect)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .contentShape(.rect)
            }
            .background(Circle().fill(.secondary))
        }
        .padding(.bottom, 8)
        .padding(.horizontal, 12)
    }

    private func popCaptureModeSetting() {}

    private func popSetting() {}
}

struct CaptureParamButton: View {
    let format: CaptureFormat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(format.rawValue)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(height: 30)
                .padding(.horizontal, 10)
        }
    }
}

// MARK: - 顶部格式标签

enum CaptureFormat: String, CaseIterable, Identifiable {
    case heif = "HEIF"
    case jpeg = "JPEG"

    var id: Self { self }
}

// MARK: - 绿色预览占位

struct GreenPreviewPlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary)
    }
}

// MARK: - 模拟相机预览背景

struct CameraPreviewPlaceholder: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.45, blue: 0.85),
                    Color(red: 0.45, green: 0.72, blue: 0.95),
                    Color(red: 0.88, green: 0.94, blue: 0.98),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Image(systemName: "mountain.2.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, -60)
                .offset(y: 40)
        }
        .ignoresSafeArea()
    }
}

// MARK: - 预览

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
