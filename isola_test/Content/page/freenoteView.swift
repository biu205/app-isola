//
//  freeNoteView.swift
//  isola_test
//
//  Created by Biu on 2026/6/7.
//
import SwiftUI
import SwiftData

struct FreeNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var activeSheet: ActiveSheet?
    @State private var inputText = ""
    
    // 照片管理
    @State private var selectedImages: [UIImage] = []
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var showCameraUnavailableAlert = false
    
    var body: some View {
        ZStack {
            // 背景紙張
            Image("paper")
                .resizable()
                .scaledToFill()
                .frame(width: 400, height: 800)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            
            // 介面層
            VStack(spacing: 0) {
                // 頂部導覽列
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                            activeSheet = nil
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.brown.opacity(0.8))
                    }
                    .padding(.trailing, 27)
                }
                .padding(.top, 150)
                .padding(.horizontal, 30)
                
                // 內容區（可滾動）
                ScrollView {
                    VStack(spacing: 10) {
                        // 標題
                        Text("隨手日記紀錄")
                            .font(.system(.title2, design: .serif))
                            .fontWeight(.medium)
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.top, 20)
                        
                        // 說明文字
                        Text("記錄一下任何想法！")
                            .font(.system(.body, design: .serif))
                            .foregroundColor(.black.opacity(0.6))
                        
                        
                        // 文字輸入區域
                        ZStack(alignment: .topLeading) {
                            if inputText.isEmpty {
                                Text("請輸入...")
                                    .font(.system(size: 18, design: .serif))
                                    .foregroundColor(.gray.opacity(0.4))
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                                    .allowsHitTesting(false)
                            }
                            
                            TextEditor(text: $inputText)
                                .font(.system(size: 18, design: .serif))
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .lineSpacing(8)
                                .padding(10)
                                .frame(maxWidth: 250, maxHeight: .infinity)
                                .foregroundColor(.black.opacity(0.8))
                            
                            
                        }
                        .frame(height: 145)
                        
                        // --- 照片區域 ---
                        ZStack(alignment: .topLeading) {
                            if !selectedImages.isEmpty {
                                VStack(spacing: 8) {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(0..<selectedImages.count, id: \.self) { index in
                                                ZStack(alignment: .topTrailing) {
                                                    Image(uiImage: selectedImages[index])
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: 65)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    
                                                    Button(action: {
                                                        selectedImages.remove(at: index)
                                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.system(size: 16))
                                                            .foregroundColor(.gray.opacity(0.8))
                                                    }
                                                    .padding(4)
                                                }
                                            }
                                        }
                                        
                                        .padding(.horizontal, 86)
                                    }
                                    .scrollClipDisabled()
                                }
                            }}.frame(height: 70)
                        
                        
                        // --- 三個按鈕 放在文字區域下方 ---
                        
                }
                    HStack(spacing: 12) {
                        // 拍照按鈕
                        Button(action: {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showCameraPicker = true
                            } else {
                                showCameraUnavailableAlert = true
                            }
                        }) {
                            VStack(spacing: 3) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                Text("拍照")
                                    .font(.system(size: 10, design: .serif))
                            }
                            .foregroundColor(.brown)
                            .frame(width: 60)
                            .padding(.vertical, 6)
                            .background(Color.brown.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(selectedImages.count >= 2)
                        .opacity(selectedImages.count >= 2 ? 0.5 : 1)
                        
                        // 上傳照片按鈕
                        Button(action: {
                            showLibraryPicker = true
                        }) {
                            VStack(spacing: 3) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 14))
                                Text("上傳照片")
                                    .font(.system(size: 10, design: .serif))
                            }
                            .foregroundColor(.brown)
                            .frame(width: 60)
                            .padding(.vertical, 6)
                            .background(Color.brown.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(selectedImages.count >= 2)
                        .opacity(selectedImages.count >= 2 ? 0.5 : 1)
                    }
                    .padding(.horizontal, 1)
                    .padding(.top, 15)
                    .padding(.bottom, 20)
                }
                // 「封入瓶子」按鈕（固定在下方）
                Button(action: saveAndClose) {
                    Text("封入瓶子")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.5) : Color.brown)
                        )
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 100)
                .padding(.bottom, 190)
            }
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            ImagePicker(image: Binding(
                get: { nil },
                set: { newImage in
                    if let image = newImage, selectedImages.count < 2 {
                        selectedImages.append(image)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            ), sourceType: .camera)
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showLibraryPicker) {
            PhotoPickerView(selectedImages: $selectedImages)
        }
        .alert("無法使用相機", isPresented: $showCameraUnavailableAlert) {
            Button("確定", role: .cancel) {}
        } message: {
            Text("此裝置不支援相機，或相機權限已被拒絕。請至設定 > isola 開啟相機權限。")
        }
    }
    
    // --- 儲存邏輯 ---
    private func saveAndClose() {
        // 轉換圖片為 DiaryMedia
        var mediaItems: [DiaryMedia] = []
        for image in selectedImages {
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                let media = DiaryMedia(mediaType: "photo", imageData: jpegData)
                mediaItems.append(media)
            }
        }
        
        let newEntry = DiaryEntry(
            title: "隨手記",
            content: inputText,
            moodIndex: nil,  // 浮標沒有心情指數
            type: "freeNote",
            mediaItems: mediaItems
        )
        
        modelContext.insert(newEntry)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            activeSheet = nil
        }
    }
}

#Preview {
    HomeView()
}
