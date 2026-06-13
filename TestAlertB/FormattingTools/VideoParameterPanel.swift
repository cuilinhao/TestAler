//
//  VideoParameterPanel.swift
//  TestAlertB
//
//  截图 1 业务包装：只负责组织 rows 数据，UI 全部交给 CaptureParameterPanel
//

import SwiftUI

/// HEIF 按钮触发的录像/拍照参数面板（色彩空间、编码格式、分辨率、帧速率）
struct VideoParameterPanel: View {
    @Binding var colorSpace: String
    @Binding var codec: String
    @Binding var resolution: String
    @Binding var frameRate: String

    var body: some View {
        CaptureParameterPanel(rows: rows)
    }

    /// 按截图 1 顺序组装参数行
    private var rows: [ParameterRow] {
        [
            .options(
                id: "colorSpace",
                title: "色彩空间",
                options: [
                    .init(id: "SDR", title: "SDR"),
                    .init(id: "HDR", title: "HDR"),
                    .init(id: "Apple Log", title: "Apple Log"),
                    .init(id: "Apple Log 2", title: "Apple Log 2"),
                ],
                selection: $colorSpace
            ),
            .options(
                id: "codec",
                title: "编码格式",
                options: [
                    .init(id: "HEVC", title: "HEVC"),
                    .init(id: "ProRes Proxy", title: "ProRes Proxy"),
                    .init(id: "ProRes LT", title: "ProRes LT"),
                    .init(id: "ProRes", title: "ProRes"),
                    .init(id: "ProRes RAW", title: "ProRes RAW"),
                ],
                selection: $codec
            ),
            .options(
                id: "resolution",
                title: "分辨率",
                options: [
                    .init(id: "FHD", title: "FHD"),
                    .init(id: "4K", title: "4K"),
                    .init(id: "片门全开", title: "片门全开"),
                ],
                selection: $resolution
            ),
            .options(
                id: "frameRate",
                title: "帧速率",
                options: [
                    .init(id: "24", title: "24"),
                    .init(id: "30", title: "30"),
                    .init(id: "60", title: "60"),
                    .init(id: "120", title: "120", isEnabled: false, showsLockWhenDisabled: true),
                ],
                selection: $frameRate
            ),
        ]
    }
}
