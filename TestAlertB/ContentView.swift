//
//  ContentView.swift
//  TestAlertB
//
//  主界面：模拟相机预览背景 + 按钮 A，点击弹出底部设置面板（弹框 B）
//

import SwiftUI


//CameraV2UI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            FeaturesToolbar()
                .frame(maxWidth: .infinity)
                .frame(height: 40)

            GreenPreviewPlaceholder()
                .frame(maxWidth: .infinity)
                .aspectRatio(3 / 4.0, contentMode: .fit)
                .layoutPriority(100)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - 顶部工具栏

struct FeaturesToolbar: View {
    var body: some View {
        HStack(spacing: 12) {
            CaptureParamButton()
                .background(Capsule().fill(.secondary))

            Spacer()

            Button(action: popCaptureModeSetting) {
                Image(systemName: "ellipsis.bubble")
                    .contentShape(.rect)
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.white)
            }
            .background(Circle().fill(.secondary))

            Button(action: popSetting) {
                Image(systemName: "gearshape")
                    .contentShape(.rect)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .contentShape(.rect)
            }
            .background(Circle().fill(.secondary))
        }
        .padding(.bottom, 8)
        .padding(.horizontal, 12)
    }

     //MARK: - 点击
    private func popCaptureModeSetting() {
        
    }

     //MARK: - 点击设置
    private func popSetting() {
        
    }
}

struct CaptureParamButton: View {
    var body: some View {
        Button(action: doAction) {
            HStack(spacing: 0) {
                Text("HEIF")
            }
            .frame(height: 30)
            .padding(.horizontal, 10)
        }
    }

     //MARK: - 点击格式选择
    private func doAction() {
        debugPrint("++++ 点击格式选择 HEIF")
    }
}

// MARK: - 绿色预览占位

struct GreenPreviewPlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(Color.green)
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
