//
//  TimerParameterPanel.swift
//  TestAlertB
//
//  截图 2 业务包装：间隔拍摄参数（拍摄间隔、拍摄时长 Slider、分辨率）
//

import SwiftUI

/// Timer 按钮触发的间隔拍摄参数面板
struct TimerParameterPanel: View {
    @Binding var captureInterval: String
    @Binding var captureDurationSeconds: Double
    @Binding var timerResolution: String

    var body: some View {
        CaptureParameterPanel(rows: rows)
    }

    /// 按截图 2 顺序组装参数行；拍摄时长真实保存 0...180
    private var rows: [ParameterRow] {
        [
            .options(
                id: "captureInterval",
                title: "拍摄间隔",
                options: [
                    .init(id: "1s", title: "1s"),
                    .init(id: "3s", title: "3s"),
                    .init(id: "5s", title: "5s"),
                    .init(id: "10s", title: "10s"),
                ],
                selection: $captureInterval
            ),
            .slider(
                id: "captureDuration",
                title: "拍摄时长",
                value: $captureDurationSeconds,
                range: 0...180,
                trailingText: "180s"
            ),
            .options(
                id: "timerResolution",
                title: "分辨率",
                options: [
                    .init(id: "FHD", title: "FHD"),
                    .init(id: "4K", title: "4K"),
                    .init(id: "片门全开", title: "片门全开"),
                ],
                selection: $timerResolution
            ),
        ]
    }
}
