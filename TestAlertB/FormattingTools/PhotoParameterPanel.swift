//
//  PhotoParameterPanel.swift
//  TestAlertB
//
//  拍照参数面板：格式 + 分辨率（单行选项 + 右侧说明文案）
//

import SwiftUI

/// Photo 按钮触发的拍照参数面板
struct PhotoParameterPanel: View {
    @Binding var photoFormat: String
    @Binding var photoResolution: String

    var body: some View {
        CaptureParameterPanel(rows: rows)
    }

    private var rows: [ParameterRow] {
        [
            .options(
                id: "photoFormat",
                title: "格式",
                options: [
                    .init(id: "HEIF", title: "HEIF"),
                    .init(id: "JPEG", title: "JPEG"),
                    .init(id: "ProRAW", title: "ProRAW"),
                ],
                selection: $photoFormat,
                layout: .inline
            ),
            .options(
                id: "photoResolution",
                title: "分辨率",
                options: [
                    .init(id: "12MP", title: "12MP"),
                    .init(id: "48MP", title: "48MP"),
                ],
                selection: $photoResolution,
                layout: .inline,
                trailingNote: "(高像素下无法连续变焦)"
            ),
        ]
    }
}
