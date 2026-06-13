//
//  ContentView.swift
//  TestAlertB
//
//  主界面：模拟相机预览背景 + 按钮 A，点击弹出底部设置面板（弹框 B）
//

import SwiftUI


//CameraV2UI

struct ContentView: View {
    @State private var selectedCaptureFormat: CaptureFormat = .heif
    @State private var isFormatPickerPresented = false

    var body: some View {
        VStack(spacing: 0) {
            FeaturesToolbar(
                selectedFormat: selectedCaptureFormat,
                onFormatTap: toggleFormatPicker
            )
                .frame(maxWidth: .infinity)
                .frame(height: 40)

            ZStack(alignment: .top) {
                GreenPreviewPlaceholder()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(3 / 4.0, contentMode: .fit)
                    .onTapGesture {
                        hideFormatPicker()
                    }

                if isFormatPickerPresented {
                    CaptureFormatPicker(selection: $selectedCaptureFormat)
                        .padding(.horizontal, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .zIndex(1)
                }
            }
            .layoutPriority(100)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
    }

     //MARK: - 点击选择格式
    private func toggleFormatPicker() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            isFormatPickerPresented.toggle()
        }
    }

    private func hideFormatPicker() {
        guard isFormatPickerPresented else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            isFormatPickerPresented = false
        }
    }
}

// MARK: - 顶部工具栏

struct FeaturesToolbar: View {
    let selectedFormat: CaptureFormat
    let onFormatTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CaptureParamButton(format: selectedFormat, action: onFormatTap)
                .background(Capsule().fill(.secondary))

            Button(action: clickTime) {
                Text("Timer")
//                Image(systemName: "fish.fill")
//                    .contentShape(.rect)
//                    .frame(width: 30, height: 30)
//                    .foregroundStyle(.white)
            }
//            .background(Circle().fill(.secondary))
            
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

    //MARK: - 点击倒计时
   private func clickTime() {
       debugPrint("++++ 点击倒计时")
   }
    
     //MARK: - 点击
    private func popCaptureModeSetting() {
        
    }

     //MARK: - 点击设置
    private func popSetting() {
        
    }
}

struct CaptureParamButton: View {
    let format: CaptureFormat
    let action: () -> Void

    var body: some View {
        Button(action: doAction) {
            HStack(spacing: 0) {
                Text(format.rawValue)
            }
            .frame(height: 30)
            .padding(.horizontal, 10)
        }
    }

     //MARK: - 点击格式选择
    private func doAction() {
        debugPrint("++++ 点击格式选择 \(format.rawValue)")
        action()
    }
}

// MARK: - 顶部格式选择

enum CaptureFormat: String, CaseIterable, Identifiable {
    case heif = "HEIF"
    case jpeg = "JPEG"

    var id: Self { self }
}

 //MARK: - 格式弹出框
struct CaptureFormatPicker: View {
    @Binding var selection: CaptureFormat
    @Namespace private var animator

    private let selectedBorderColor = Color(red: 230 / 255, green: 100 / 255, blue: 40 / 255)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CaptureFormat.allCases) { format in
                Button {
                    debugPrint("++++ 选择格式 \(format.rawValue)")
                    selection = format
                } label: {
                    Text(format.rawValue)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .contentShape(Rectangle())
                        .background {
                            if selection == format {
                                ZStack {
                                    Capsule()
                                        .fill(.black.opacity(0.3))
                                    Capsule()
                                        .stroke(selectedBorderColor, lineWidth: 1)
                                }
                                .matchedGeometryEffect(id: "capture-format-selection", in: animator)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: selection)
        .environment(\.colorScheme, .dark)
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
