//
//  SettingItemModel.swift
//  TestAlertB
//
//  Created by Linhao-Mac on 2026/6/12.
//

import Foundation

// MARK: - 数据模型

/// 网格中的一个 setting 按钮描述（布局 + 交互类型）
struct SettingItem: Identifiable {
    /// 使用稳定的字符串 id（而非 UUID()），保证视图重建后展开/选中状态不丢失
    let id: String
    let kind: SettingItemKind
    let position: ButtonPosition

    /// 转为业务枚举，便于 switch 分支
    var itemID: CameraSettings.ItemID? {
        CameraSettings.ItemID(rawValue: id)
    }

    /// 固定中文标题，来自 CameraSettings.ItemID
    var title: String {
        itemID?.displayTitle ?? id
    }

    /// 收起态 UI 类型，来自 CameraSettings.ItemID 映射
    var collapsedStyle: CameraSettings.CollapsedStyle {
        itemID?.collapsedStyle ?? .toggleIcon(offSystemName: "questionmark.circle", onSystemName: "questionmark.circle", title: title)
    }
}
