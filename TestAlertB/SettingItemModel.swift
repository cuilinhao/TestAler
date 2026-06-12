//
//  SettingItemModel.swift
//  TestAlertB
//
//  Created by Linhao-Mac on 2026/6/12.
//

import Foundation

// MARK: - 数据模型

struct SettingItem: Identifiable {
    /// 使用稳定的字符串 id（而非 UUID()），保证视图重建后展开/选中状态不丢失
    let id: String
    let kind: SettingItemKind
    let position: ButtonPosition

    var itemID: CameraSettings.ItemID? {
        CameraSettings.ItemID(rawValue: id)
    }

    var title: String {
        itemID?.displayTitle ?? id
    }

    var collapsedStyle: CameraSettings.CollapsedStyle {
        itemID?.collapsedStyle ?? .toggleIcon(systemName: "questionmark.circle", title: title)
    }
}
