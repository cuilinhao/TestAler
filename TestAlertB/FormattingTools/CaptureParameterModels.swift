//
//  CaptureParameterModels.swift
//  TestAlertB
//
//  顶部参数面板数据模型：只描述「有什么参数」，不包含任何 UI 逻辑
//

import SwiftUI

// MARK: - 面板激活态

/// 父层用单一枚举管理顶部参数面板互斥，避免多个 Bool 同时为 true
enum ActiveParameterPanel: Hashable {
    /// 截图 1：HEIF 按钮触发
    case video
    /// 截图 2：Timer 按钮触发
    case timer
    /// 拍照参数：Photo 按钮触发
    case photo
}

// MARK: - Options 布局

/// options 行的排布方式：grid 为两列网格，inline 为单行横向
enum ParameterOptionsLayout: Hashable {
    case grid
    case inline
}

// MARK: - 选项

/// 单个可选项：id 用于状态持久化，title 用于展示
struct ParameterOption: Identifiable, Hashable {
    let id: String
    let title: String
    var isEnabled: Bool = true
    /// 禁用时是否显示锁图标（如帧速率 120）
    var showsLockWhenDisabled: Bool = false
}

// MARK: - 行类型

/// 面板行：options 为两列网格；slider 为拍摄时长等连续值
enum ParameterRow: Identifiable {
    case options(
        id: String,
        title: String,
        options: [ParameterOption],
        selection: Binding<String>,
        layout: ParameterOptionsLayout = .grid,
        trailingNote: String? = nil
    )
    case slider(
        id: String,
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        trailingText: String
    )

    var id: String {
        switch self {
        case .options(let id, _, _, _, _, _):
            return id
        case .slider(let id, _, _, _, _):
            return id
        }
    }
}
