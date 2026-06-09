import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

struct QuestionView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var activeSheet: ActiveSheet?
    @State private var inputText = ""
    
    // 狀態管理：0 = 選心情, 1 = 寫日記
    @State private var currentState: Int = 0
    @State private var selectedMoodIndex: Int = 2
    
    // 照片管理
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var showPhotoPicker = false
    @State private var cameraSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    let question: JournalQuestion
    var onSaved: (() -> Void)? = nil

    let moodImages = ["非常不愉快度Ｑ", "不愉快度Ｑ", "度Ｑ", "愉快度Ｑ", "非常愉快度Ｑ"]
    let moodName = ["非常不愉快", "不愉快", "一般", "愉快", "非常愉快"]
    
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
                    if currentState == 1 {
                        Button(action: {
                            withAnimation(.spring()) { currentState = 0 }
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                            }
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.brown.opacity(0.8))
                        }
                        .padding(.leading, 30)
                    }
                    
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
                
                // 內容切換區
                VStack(spacing: 25) {
                    if currentState == 0 {
                        // 第一階段：選擇心情
                        moodSelectionSection
                            .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                    } else {
                        // 第二階段：寫日記 + 上傳照片
                        diaryInputSection
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.bottom, 150)
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
    
    // --- 子視圖：心情選擇 ---
    private var moodSelectionSection: some View {
        VStack(spacing: 30) {
            Text("今天心情如何呢？")
                .font(.system(.title3, design: .serif))
                .fontWeight(.medium)
                .foregroundColor(.black.opacity(0.7))
            
            ZStack {
                ForEach(0..<5) { index in
                    if selectedMoodIndex == index {
                        VStack {
                            Image(moodImages[index])
                                .resizable()
                                .scaledToFit()
                                .frame(width: 190, height: 190)
                                .transition(.scale.combined(with: .opacity))
                            
                            Text(moodName[index])
                                .font(.system(.title3, design: .serif))
                                .fontWeight(.medium)
                                .foregroundStyle(.black.opacity(0.7))
                        }
                    }
                }
            }
            .frame(height: 200)
            
            Slider(value: Binding(
                get: { Double(selectedMoodIndex) },
                set: { newValue in
                    let roundedValue = Int(newValue.rounded())
                    if roundedValue != selectedMoodIndex {
                        selectedMoodIndex = roundedValue
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                }
            ), in: 0...4, step: 1)
            .accentColor(.brown)
            .padding(.horizontal, 70)
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentState = 1 }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Text("下一步")
                    .font(.system(.headline, design: .serif))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Capsule().stroke(Color.brown, lineWidth: 1.5))
                    .foregroundColor(.brown)
            }
        }
    }
    
    // --- 子視圖：日記輸入 + 照片上傳 ---
    private var diaryInputSection: some View {
        VStack(spacing: 15) {
            Text(question.text)
                .font(.system(.headline, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundColor(.black.opacity(0.7))
                .padding(.horizontal, 100)
                .padding(.top, 20)
            
            // --- 照片區域 ---
            if question.requireImage {
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
            .frame(height: 200)
            
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
            title: question.text,
            content: inputText,
            moodIndex: selectedMoodIndex,
            type: "daily",
            mediaItems: mediaItems
        )
        
        modelContext.insert(newEntry)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        onSaved?()

        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            activeSheet = nil
        }
    }
}

// MARK: - ImagePicker 輔助視圖
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var image: Binding<UIImage?>
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        if sourceType == .camera {
            picker.mediaTypes = ["public.image"]
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image.wrappedValue = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - PhotoPicker 輔助視圖（iOS 16+）
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.mediaTypes = ["public.image"]
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                if parent.selectedImages.count < 5 {
                    parent.selectedImages.append(image)
                }
            }
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    HomeView()
}
