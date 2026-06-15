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

    /// 首页进入设置面板的业务模式：复用同一个 Sheet，只替换内部 rows 数据
    enum SheetMode: Hashable {
        /// 拍照参数
        case photo
        ///  视频录制
        case video
        
        /// 延时摄影
        case timeLapse
        /// 低速快门
        case longExposure
    }
    
    

    /// 网格里每个 setting 的稳定标识，与 SettingItem.id 一一对应
    enum ItemID: String, CaseIterable {
        case ratio          // 比例：
        case timer          // 倒计时
        case live           // LIVE
        case grid           // 网格：
        case level          // 水平
        case histogram      // 直方图
        case focusAssist    // 对焦
        case watermark      // 水印
        case telephoto      // 长焦模式
        case diving         // 潜水
        case voice          // 音频表
        case logRestore     // Log
        case stabilization  // 防抖
    }

    /// 收起态 UI 类型：CapsuleCollapsedContentView 按此路由到不同子 View
    enum CollapsedStyle: Equatable {
        /// 比例：左侧值 badge + 右侧固定标题
        case valueBadge(title: String)
        /// 可选值：未选择时 icon + 标题；选择后 value badge + 标题
        /// 比如 logo 防抖
        case optionalValueBadge(offSystemName: String, title: String)
        /// 倒计时：左侧动态指示（斜杠 timer / 圆 badge 秒数）+ 右侧固定标题
        case countdownIndicator(title: String)
        /// 开关 / 功能项：icon + 标题；ON/OFF 可配置不同 SF Symbol（如 LIVE）
        case toggleIcon(offSystemName: String, onSystemName: String, title: String)
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

    /// 拍照倒计时选项（关闭 / 3秒 / 10秒）
    enum Countdown: String, CaseIterable, Identifiable {
        case off = "关闭"
        case three = "3秒"
        case ten = "10秒"

        var id: String { rawValue }

        /// 默认初始态：关闭（斜杠 timer）
        static var defaultValue: Self { .off }

        /// 选中 3秒/10秒 时对应的秒数；关闭为 nil
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

        /// 收起态左侧指示类型
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
        case .voice: return "音频表"
        case .logRestore: return "Log还原"
        case .stabilization: return "防抖"
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
            // OFF：同心圆 + 斜杠；ON：同心圆（与系统相机 Live Photo 一致）
            return .toggleIcon(offSystemName: "livephoto.slash", onSystemName: "livephoto", title: displayTitle)
        case .grid:
            return .toggleIcon(offSystemName: "grid", onSystemName: "grid", title: displayTitle)
        case .level:
            return .toggleIcon(offSystemName: "smallcircle.filled.circle", onSystemName: "smallcircle.filled.circle", title: displayTitle)
        case .histogram:
            return .toggleIcon(offSystemName: "chart.bar.fill", onSystemName: "chart.bar.fill", title: displayTitle)
        case .focusAssist:
            return .toggleIcon(offSystemName: "camera.metering.spot", onSystemName: "camera.metering.spot", title: displayTitle)
        case .watermark:
            return .toggleIcon(offSystemName: "water.waves", onSystemName: "water.waves", title: displayTitle)
        case .telephoto:
            return .toggleIcon(offSystemName: "plus.magnifyingglass", onSystemName: "plus.magnifyingglass", title: displayTitle)
        case .diving:
            return .toggleIcon(offSystemName: "drop", onSystemName: "drop", title: displayTitle)
        case .voice:
            return .toggleIcon(offSystemName: "waveform", onSystemName: "waveform", title: displayTitle)
        case .logRestore:
            return .optionalValueBadge(offSystemName: "film", title: displayTitle)
        case .stabilization:
            return .optionalValueBadge(offSystemName: "viewfinder", title: displayTitle)
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
