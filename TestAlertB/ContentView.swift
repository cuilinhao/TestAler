//
//  ContentView.swift
//  TestAlertB
//
//  主界面：模拟相机预览背景 + 按钮 A，点击弹出底部设置面板（弹框 B）
//

import SwiftUI

struct ContentView: View {
    @State private var isSheetPresented = false

    var body: some View {
        ZStack {
            // 模拟相机取景画面（渐变天空 + 雪山剪影），让毛玻璃面板能透出底色
            CameraPreviewPlaceholder()

            // 按钮 A：点击弹出弹框 B
            VStack {
                Spacer()
                HStack(spacing: 25) {
                    Button() {
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
                .padding(.bottom, 440)
            }
        }
        // 弹框 B 作为全屏覆盖层呈现，便于实现自定义形变交互
        .overlay {
            CameraSettingsSheet(isPresented: $isSheetPresented) {
                // 倒计时 3→2→1 走完后回调；面板可已收起，Task 不随 dismiss 中断
                // TODO: 触发相机拍照
                TestLog.log("倒计时结束开始拍照")
            }
        }
        .preferredColorScheme(.dark)
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
