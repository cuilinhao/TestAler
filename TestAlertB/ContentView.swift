//
//  ContentView.swift
//  TestAlertB
//
//  主界面：模拟相机预览背景 + 按钮 A，点击弹出底部设置面板（弹框 B）
//

import SwiftUI

struct ContentView: View {
    @State private var isSheetPresented = false
    @State private var sheetMode: CameraSettings.SheetMode = .photo
    /// 比例状态：拍照/录像分开存，供 Sheet 与测试按钮共用
    @State private var aspectRatios: [CameraSettings.SheetMode: CameraSettings.AspectRatio] = [
        .photo: .ratio4x3,
        .video: .ratio4x3,
    ]
    /// 选项型 item 的选中值，供 Sheet 与测试按钮共用
    @State private var optionSelectionsByMode: [CameraSettings.SheetMode: [String: String]] = [:]

    var body: some View {
        ZStack {
            // 模拟相机取景画面（渐变天空 + 雪山剪影），让毛玻璃面板能透出底色
            CameraPreviewPlaceholder()

            // 按钮 A：点击弹出弹框 B
            VStack {
                Spacer()
                VStack(spacing: 30) {
                    HStack(spacing: 25) {
                        Button() {
                            sheetMode = .photo
                            isSheetPresented = true
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .padding(18)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .environment(\.colorScheme, .dark)
                                
                                Text("拍照设置页")
                                    .font(.body)
                                    .foregroundStyle(.green)
                            }
                            
                        }
                        Button() {
                            sheetMode = .video
                            isSheetPresented = true
                            debugPrint("++++ 展示录像设置页面 ")
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "fish.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .padding(18)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .environment(\.colorScheme, .dark)
                                Text("录像设置页")
                                    .font(.body)
                                    .foregroundStyle(.green)
                            }
                            
                        }
                    }
                    
                    HStack(spacing: 25) {
                        Button() {
                            sheetMode = .photo
                            isSheetPresented = true
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .padding(18)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .environment(\.colorScheme, .dark)
                                
                                Text("延时摄影设置页")
                                    .font(.body)
                                    .foregroundStyle(.green)
                            }
                            
                        }
                        Button() {
                            sheetMode = .video
                            isSheetPresented = true
                            debugPrint("++++ 展示录像设置页面 ")
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "fish.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .padding(18)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .environment(\.colorScheme, .dark)
                                Text("低速快门设置页")
                                    .font(.body)
                                    .foregroundStyle(.green)
                            }
                            
                        }
                    }
                    
                    HStack(spacing: 25) {
                        //MARK: - TEST
                        Button() {
                            debugPrint("++++ 点击设置比为16:9 ")
                            test1()
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "fish.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .padding(18)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .environment(\.colorScheme, .dark)
                                Text("点击设置比为16:9")
                                    .font(.body)
                                    .foregroundStyle(.green)
                            }
                            
                        }
                        
                        
                        Button() {
                            debugPrint("++++ 点击设置防抖为标准 ")
                            test2()
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "fish.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .padding(18)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .environment(\.colorScheme, .dark)
                                Text("点击设置防抖为标准")
                                    .font(.body)
                                    .foregroundStyle(.green)
                            }
                            
                        }
                    }
                    
                }
                .padding(.bottom, 440)
            }
        }
        // 弹框 B 作为全屏覆盖层呈现，便于实现自定义形变交互
        .overlay {
            CameraSettingsSheet(
                isPresented: $isSheetPresented,
                mode: sheetMode,
                aspectRatios: $aspectRatios,
                optionSelectionsByMode: $optionSelectionsByMode
            )
        }
        .preferredColorScheme(.dark)
    }
    
    
    /// 测试：将拍照/录像比例都设为 16:9
    func test1() {
        aspectRatios[.photo] = .ratio16x9
        aspectRatios[.video] = .ratio16x9
        debugPrint("++++ 比例已设为 16:9, photo=\(aspectRatios[.photo]?.rawValue ?? ""), video=\(aspectRatios[.video]?.rawValue ?? "")")
        TestLog.log("test1 比例设为 16:9")
    }

    /// 测试：将录像防抖选项设为「标准」
    func test2() {
        var selections = optionSelectionsByMode
        var videoOptions = selections[.video] ?? [:]
        videoOptions[CameraSettings.ItemID.stabilization.rawValue] = "标准"
        selections[.video] = videoOptions
        optionSelectionsByMode = selections
        debugPrint("++++ 录像防抖已设为 标准")
        TestLog.log("test2 录像防抖设为 标准")
    }
}

// MARK: - 模拟相机预览背景

struct CameraPreviewPlaceholder: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.45, blue: 0.85),
                    Color(red: 0.45, green: 0.72, blue: 0.95),
                    Color(red: 0.88, green: 0.94, blue: 0.98),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Image(systemName: "mountain.2.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, -60)
                .offset(y: 40)
        }
        .ignoresSafeArea()
    }
}

// MARK: - 预览

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
