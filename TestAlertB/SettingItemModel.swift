//
//  SettingItemModel.swift
//  TestAlertB
//
//  Created by Linhao-Mac on 2026/6/12.
//

import Foundation
import UIKit

//MARK: - 数据模型
struct SettingItem: Identifiable {
   /// 使用稳定的字符串 id（而非 UUID()），保证视图重建后展开/选中状态不丢失
   let id: String
   let icon: String
   let title: String
   let kind: SettingItemKind
   let position: ButtonPosition
}
