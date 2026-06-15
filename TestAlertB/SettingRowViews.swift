//
//  SettingRowViews.swift
//  TestAlertB
//
//  小格行（3 等分）与大格行（2 等分）的布局容器
//

import SwiftUI

// MARK: - 行容器

 //MARK: - 小长方形行

/// 小长方形行：一行 3 个等分格
struct SmallSettingRowView<Cell: View>: View {
    let items: [SettingItem]
    let rowIndex: Int
    @ViewBuilder let cell: (SettingItem, Int, ButtonPosition) -> Cell

    var body: some View {
        SettingRowHStack(
            items: items,
            columnCount: SettingRowLayout.small.columnCount,
            rowIndex: rowIndex,
            cell: cell
        )
    }
}

//MARK: - 大长方形行

/// 大长方形行：一行 2 个等分格
struct LargeSettingRowView<Cell: View>: View {
    let items: [SettingItem]
    let rowIndex: Int
    @ViewBuilder let cell: (SettingItem, Int, ButtonPosition) -> Cell

    var body: some View {
        SettingRowHStack(
            items: items,
            columnCount: SettingRowLayout.large.columnCount,
            rowIndex: rowIndex,
            cell: cell
        )
    }
}

// MARK: - 共用行布局

/// 等分 HStack：按 index 推导左/中/右，再渲染每个格子的胶囊
private struct SettingRowHStack<Cell: View>: View {
    let items: [SettingItem]
    let columnCount: Int
    let rowIndex: Int
    @ViewBuilder let cell: (SettingItem, Int, ButtonPosition) -> Cell

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let position = ButtonPosition.derived(index: index, columnCount: columnCount)
                cell(item, index, position)
            }
        }
        .onAppear {
            TestLog.log(
                "row appear index=\(rowIndex), columns=\(columnCount), items=\(items.map(\.id).joined(separator: " -> "))"
            )
        }
    }
}
