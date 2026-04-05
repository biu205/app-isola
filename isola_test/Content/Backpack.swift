import SwiftUI
import SwiftData

struct Backpack: View {
    @Environment(\.modelContext) private var modelContext
    
    // 自動抓取資料，依日期排序
    @Query(sort: \DiaryEntry.date, order: .reverse) private var entries: [DiaryEntry]
    
    // 編輯狀態
    @State private var entryToEdit: DiaryEntry?
    
    // 💡 為了維持一致性，這裡定義與 QuestionView 相同的對應表
    let moodImages = ["非常不愉快度Ｑ", "不愉快度Ｑ", "度Ｑ", "愉快度Ｑ", "非常愉快度Ｑ"]
    let moodNames = ["非常不愉快", "不愉快", "一般", "愉快", "非常愉快"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if entries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "backpack.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("背包裡空空的")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("去海灘撿個瓶子寫下今天的心情吧！")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(entries) { entry in
                            Button {
                                entryToEdit = entry
                            } label: {
                                HStack(spacing: 16) {
                                    // 💡 亮點：顯示當時選的心情度Ｑ
                                    // 這裡做一個安全防護，確保 Index 不會越界
                                    let moodIndex = max(0, min(4, entry.moodIndex))
                                    
                                    Image(moodImages[moodIndex])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 48, height: 48)
                                        .background(Circle().fill(Color.white.opacity(0.6))) // 輕微底色讓圖示更突出
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(entry.title)
                                                .font(.system(.headline, design: .serif))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text(entry.date, format: .dateTime.month().day())
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        // 顯示內容摘要與心情文字
                                        Text("[\(moodNames[moodIndex])] \(entry.content)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1) // 保持背包整潔，只顯示一行
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("我的背包")
            .sheet(item: $entryToEdit) { entry in
                EditDiaryView(entry: entry)
            }
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

// MARK: - 編輯視窗組件
struct EditDiaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: DiaryEntry
    
    let moodImages = ["非常不愉快度Ｑ", "不愉快度Ｑ", "度Ｑ", "愉快度Ｑ", "非常愉快度Ｑ"]
    let moodNames = ["非常不愉快", "不愉快", "一般", "愉快", "非常愉快"]
    
    var body: some View {
        NavigationStack {
            Form {
                // 💡 新增：顯示當時的心情狀態（不可修改，作為回憶標籤）
                Section(header: Text("當時的心情")) {
                    HStack(spacing: 15) {
                        Image(moodImages[max(0, min(4, entry.moodIndex))])
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                        
                        VStack(alignment: .leading) {
                            Text(moodNames[max(0, min(4, entry.moodIndex))])
                                .font(.headline)
                            Text(entry.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("題目")) {
                    Text(entry.title)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                
                Section(header: Text("內容")) {
                    TextEditor(text: $entry.content)
                        .frame(minHeight: 250)
                        .font(.body)
                        .lineSpacing(6)
                }
            }
            .navigationTitle("編輯日記")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    // Preview 需要塞一個假記憶體資料庫才能預覽，這在開發階段很實用
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DiaryEntry.self, configurations: config)
    
    // 塞一筆假資料
    let sample = DiaryEntry(title: "測試題目", content: "這是一段測試的日記內容。")
    container.mainContext.insert(sample)
    
    return Backpack()
        .modelContainer(container)
}
