//
//  CameraSettings.swift
//  TestAlertB
//
//  相机设置项业务枚举：数据与 UI 映射分离，View 只消费 CollapsedStyle / rawValue
//

import Foundation

/// 相机设置面板所有业务枚举的命名空间
enum CameraSettings {}

extension CameraSettings {

    /// 网格里每个 setting 的稳定标识，与 SettingItem.id 一一对应
    enum ItemID: String, CaseIterable {
        case ratio
        case timer
        case live
        case grid
        case level
        case histogram
        case focusAssist
        case watermark
        case telephoto
        case diving
        case voice
    }

    /// 收起态 UI 类型：CapsuleCollapsedContentView 按此路由到不同子 View
    enum CollapsedStyle: Equatable {
        /// 比例：左侧值 badge + 右侧固定标题
        case valueBadge(title: String)
        /// 倒计时：左侧动态指示（斜杠 timer / 圆 badge 秒数）+ 右侧固定标题
        case countdownIndicator(title: String)
        /// 开关 / 功能项：icon + 标题；ON 态黄底由 CapsuleChromeBackground 负责
        case toggleIcon(systemName: String, title: String)
    }

    /// 拍摄比例选项
    enum AspectRatio: String, CaseIterable, Identifiable {
        case ratio1x1 = "1:1"
        case ratio4x3 = "4:3"
        case ratio16x9 = "16:9"

        var id: String { rawValue }

        /// 未选择时的默认展示值
        static var defaultValue: Self { .ratio4x3 }

        /// 收起态 badge 与展开态 segment 共用的文案
        var displayText: String { rawValue }
    }

    /// 拍照倒计时选项（选 3秒/10秒 会触发一次倒计时，结束后回到 .off）
    enum Countdown: String, CaseIterable, Identifiable {
        case off = "关闭"
        case three = "3秒"
        case ten = "10秒"

        var id: String { rawValue }

        /// 默认初始态：关闭（图2 斜杠 timer）
        static var defaultValue: Self { .off }

        /// 选中 3秒/10秒 时实际倒计时的秒数；关闭为 nil
        var durationSeconds: Int? {
            switch self {
            case .off:
                return nil
            case .three:
                return 3
            case .ten:
                return 10
            }
        }

        /// 收起态左侧指示类型（静态配置用；运行中由 countdownRemainingSeconds 驱动 UI）
        enum Leading: Equatable {
            case slashTimer
            case seconds(Int)
        }

        var leading: Leading {
            switch self {
            case .off:
                return .slashTimer
            case .three:
                return .seconds(3)
            case .ten:
                return .seconds(10)
            }
        }

        init?(selection: String?) {
            guard let selection, let value = Countdown(rawValue: selection) else { return nil }
            self = value
        }
    }
}

extension CameraSettings.ItemID {

    /// 胶囊右侧/展开菜单使用的固定中文标题
    var displayTitle: String {
        switch self {
        case .ratio: return "比例"
        case .timer: return "倒计时"
        case .live: return "LIVE"
        case .grid: return "网格"
        case .level: return "水平仪"
        case .histogram: return "直方图"
        case .focusAssist: return "对焦辅助"
        case .watermark: return "水印"
        case .telephoto: return "长焦模式"
        case .diving: return "潜水模式"
        case .voice: return "音频"
        }
    }

    /// 每个 item 对应的收起态 UI 类型，业务映射集中在此处
    var collapsedStyle: CameraSettings.CollapsedStyle {
        switch self {
        case .ratio:
            return .valueBadge(title: displayTitle)
        case .timer:
            return .countdownIndicator(title: displayTitle)
        case .live:
            return .toggleIcon(systemName: "livephoto.slash", title: displayTitle)
        case .grid:
            return .toggleIcon(systemName: "grid", title: displayTitle)
        case .level:
            return .toggleIcon(systemName: "smallcircle.filled.circle", title: displayTitle)
        case .histogram:
            return .toggleIcon(systemName: "chart.bar.fill", title: displayTitle)
        case .focusAssist:
            return .toggleIcon(systemName: "camera.metering.spot", title: displayTitle)
        case .watermark:
            return .toggleIcon(systemName: "water.waves", title: displayTitle)
        case .telephoto:
            return .toggleIcon(systemName: "plus.magnifyingglass", title: displayTitle)
        case .diving:
            return .toggleIcon(systemName: "drop", title: displayTitle)
        case .voice:
            return .toggleIcon(systemName: "waveform", title: displayTitle)
        }
    }
}

extension CameraSettings.CollapsedStyle {

    /// 是否为 toggle 型收起 UI（ON 态需要整颗胶囊变黄）
    var isToggleIcon: Bool {
        if case .toggleIcon = self { return true }
        return false
    }
}
