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
    @State private var showImagePicker = false
    @State private var showPhotoPicker = false
    @State private var cameraSourceType: UIImagePickerController.SourceType = .photoLibrary
    
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
            VStack {
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
                
                // 內容區
                VStack(spacing: 15) {
                    // 標題
                    Text("隨手日記紀錄")
                        .font(.system(.headline, design: .serif))
                        .fontWeight(.medium)
                        .foregroundColor(.black.opacity(0.7))
                        .padding(.top, 20)
                    
                    // 說明文字
                    Text("記錄一下都法！")
                        .font(.system(.body, design: .serif))
                        .foregroundColor(.black.opacity(0.6))
                    
                    // --- 照片區域 ---
                    VStack(spacing: 12) {
                        // 照片網格顯示
                        if !selectedImages.isEmpty {
                            ZStack(alignment: .topTrailing) {
                                HStack(spacing: 8) {
                                    ForEach(0..<min(3, selectedImages.count), id: \.self) { index in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: selectedImages[index])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            Button(action: {
                                                selectedImages.remove(at: index)
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.red.opacity(0.8))
                                                    .background(Color.white.clipShape(Circle()))
                                            }
                                            .padding(6)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                
                                // 顯示 +N（如果超過3張）
                                if selectedImages.count > 3 {
                                    Text("+\(selectedImages.count - 3)")
                                        .font(.system(.headline, design: .serif))
                                        .foregroundColor(.brown)
                                        .padding(8)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // 三個操作按鈕
                        HStack(spacing: 16) {
                            // 拍照按鈕
                            Button(action: {
                                cameraSourceType = .camera
                                showImagePicker = true
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18))
                                    Text("拍照")
                                        .font(.system(size: 12, design: .serif))
                                }
                                .foregroundColor(.brown)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.brown.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .disabled(selectedImages.count >= 5)
                            .opacity(selectedImages.count >= 5 ? 0.5 : 1)
                            
                            // 上傳照片按鈕
                            Button(action: {
                                showPhotoPicker = true
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 18))
                                    Text("上傳照片")
                                        .font(.system(size: 12, design: .serif))
                                }
                                .foregroundColor(.brown)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.brown.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .disabled(selectedImages.count >= 5)
                            .opacity(selectedImages.count >= 5 ? 0.5 : 1)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 文字輸入區域
                    ZStack(alignment: .topLeading) {
                        if inputText.isEmpty {
                            Text("請輸入")
                                .font(.system(size: 18, design: .serif))
                                .foregroundColor(.gray.opacity(0.4))
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 18)
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
                    .frame(height: 180)
                    
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                .padding(.bottom, 100)
                
                // 儲存按鈕
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
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: Binding(
                get: { nil },
                set: { newImage in
                    if let image = newImage, selectedImages.count < 5 {
                        selectedImages.append(image)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            ), sourceType: cameraSourceType)
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(selectedImages: $selectedImages)
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
            title: "隨手日記",
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
