//
//  CameraSettings.swift
//  TestAlertB
//
//  相机设置项业务枚举：数据与 UI 映射分离，View 只消费 CollapsedStyle / rawValue
//

import Foundation

enum CameraSettings {}

extension CameraSettings {

    /// 网格里每个 setting 的稳定标识
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

    /// 收起态 UI 类型：不同 case 对应不同 Collapsed 子 View
    enum CollapsedStyle: Equatable {
        case valueBadge(title: String)
        case countdownIndicator(title: String)
        case toggleIcon(systemName: String, title: String)
    }

    enum AspectRatio: String, CaseIterable, Identifiable {
        case ratio1x1 = "1:1"
        case ratio4x3 = "4:3"
        case ratio16x9 = "16:9"

        var id: String { rawValue }

        static var defaultValue: Self { .ratio4x3 }

        var displayText: String { rawValue }
    }

    enum Countdown: String, CaseIterable, Identifiable {
        case off = "关闭"
        case three = "3秒"
        case ten = "10秒"

        var id: String { rawValue }

        static var defaultValue: Self { .off }

        /// 收起态左侧指示：关闭用斜杠 timer，已设置用圆 badge 数字
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

    var isToggleIcon: Bool {
        if case .toggleIcon = self { return true }
        return false
    }
}
