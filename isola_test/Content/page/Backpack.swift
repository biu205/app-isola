import SwiftUI
import SwiftData

struct Backpack: View {
    @State private var currentMonth: Date = Date()
    // 新增：控制選擇器彈出的狀態
    @State private var showDatePicker = false
    @Environment(\.modelContext) private var modelContext

    // 新增：用於選擇器內部的暫存狀態
    @State private var selectedYear: Int = 2026
    @State private var selectedMonth: Int = 4
    // 自動抓取資料，依日期排序
    @Query(sort: \DiaryEntry.date, order: .reverse) private var entries: [DiaryEntry]

    // 編輯狀態
    @State private var entryToEdit: DiaryEntry?

    // 💡 為了維持一致性，這裡定義與 QuestionView 相同的對應表
    let moodImages = ["非常不愉快度Ｑ", "不愉快度Ｑ", "度Ｑ", "愉快度Ｑ", "非常愉快度Ｑ"]
    let moodNames = ["非常不愉快", "不愉快", "一般", "愉快", "非常愉快"]
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)

    var body: some View {
            // 核心優化：將月曆與列表統一放進同一個 VStack 管理
            VStack(spacing: 0) {
                // 1. 頂部導航與月份標題
                dynamicYearHeader
                    .padding(.top, 40)
                    .padding(.bottom, 10)
                
                monthHeader
                    .padding(.top, 0)
                    .padding(.bottom, 20)
                
                // 2. 星期標題列
                weekdayHeader
                
                // 3. 真實的日曆網格
                calendarGrid
                    .padding(.horizontal, 20)
                
                // 4. 下半部：日記背包列表 (取代了原本的 Spacer 和 NavigationStack)
                ZStack {
                    
                    // 這裡可以統一用你的主題色，或者保留系統群組色
                    Color(hex: "#FFFCF1")
                        .ignoresSafeArea(edges: .bottom)

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
                                        let moodIndex = max(0, min(4, entry.moodIndex))
                                        // 記得確保你有把這些圖片放進 Assets 裡
                                        Image(moodImages[moodIndex])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 48, height: 48)
                                            .background(Circle().fill(Color.white.opacity(0.6)))
                                        
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
                                            
                                            Text("[\(moodNames[moodIndex])] \(entry.content)")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .onDelete(perform: deleteEntries)
                        }
                        .listStyle(.plain) // 💡 競賽加分亮點：移除 List 預設的醜陋灰色背景，讓它完美融入你的 App 視覺
                      
                    }
                }  .padding(.top,40)
            }
        
            .background(Color(hex: "#FFFCF1").ignoresSafeArea())
            
            // 所有的彈出視窗 (Sheet) 統一掛在最外層的 VStack 上
            .sheet(item: $entryToEdit) { entry in
                EditDiaryView(entry: entry)
            }
            .sheet(isPresented: $showDatePicker) {
                MonthYearPickerView(
                    selectedYear: $selectedYear,
                    selectedMonth: $selectedMonth,
                    onConfirm: {
                        updateCurrentMonth()
                    }
                )
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
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

// MARK: - UI 組件拆分
private extension Backpack {
    
    var dynamicYearHeader: some View {
        HStack {
            let year = calendar.component(.year, from: currentMonth)
            Text("\(String(year))")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(.black)
        }
    }
    
    var systemWeekdays: [String] {
        Calendar.current.veryShortWeekdaySymbols
    }
    
    var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(systemWeekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(.secondary)
                    .foregroundStyle(Color(hex: "#000000"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
    
    var monthHeader: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.black)
            }
            
            Spacer()
            
            Text(monthString(from: currentMonth))
                .font(.system(size: 32, weight: .medium, design: .serif))
                .tracking(4)
                .foregroundColor(.black)
                .onTapGesture(count: 2) {
                    let now = Date()
                    currentMonth = now
                    selectedYear = calendar.component(.year, from: now)
                    selectedMonth = calendar.component(.month, from: now)
                }
                .onTapGesture {
                    selectedYear = calendar.component(.year, from: currentMonth)
                    selectedMonth = calendar.component(.month, from: currentMonth)
                    showDatePicker = true
                }
            
            Spacer()
            
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.black)
            }
        }
        .padding(.horizontal, 40)
    }
    
    var calendarGrid: some View {
        let daysInMonth = daysInMonth(for: currentMonth)
        let firstDayOffset = firstWeekdayOffset(for: currentMonth)
        
        return LazyVGrid(columns: columns, spacing: 25) {
            if firstDayOffset > 0 {
                ForEach(-firstDayOffset..<0, id: \.self) { _ in
                    Color.clear
                        .frame(height: 32)
                }
            }
            
            ForEach(1...daysInMonth, id: \.self) { day in
                VStack(spacing: 8) {
                    Text("\(day)")
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(.black)
                    
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 32)
                }
            }
        }
    }
}

// MARK: - 日曆邏輯運算
private extension Backpack {
    
    func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date).uppercased()
    }
    
    func daysInMonth(for date: Date) -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: date) else { return 30 }
        return range.count
    }
    
    func firstWeekdayOffset(for date: Date) -> Int {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return 0 }
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        return weekday - 1
    }
    
    // 將選好的年月更新回 currentMonth
    func updateCurrentMonth() {
        var components = calendar.dateComponents([.year, .month, .day], from: currentMonth)
        components.year = selectedYear
        components.month = selectedMonth
        if let newDate = calendar.date(from: components) {
            currentMonth = newDate
        }
    }
}

// MARK: - 獨立的年月選擇器視圖 (Clean Architecture)
struct MonthYearPickerView: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    var onConfirm: () -> Void
    
    @Environment(\.dismiss) var dismiss // 用於關閉 Sheet
    
    // 預設年份範圍 (例如：往前 10 年，往後 10 年)
    let years = Array(2000...2099)
    let months = Array(1...12)
    
    var body: some View {
        VStack {
            // 頂部按鈕列
            HStack {
                Button("取消") {
                    dismiss()
                }
                .foregroundStyle(.gray)
                
                Spacer()
                
                Button("確認") {
                    onConfirm()
                    dismiss()
                }
                .fontWeight(.bold)
            }
            .padding()
            
            // 原生滾輪選擇器
            HStack(spacing: 0) {
                // 年份滾輪
                Picker("Year", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text("\(String(year))年").tag(year)
                    }
                }
                .pickerStyle(.wheel)
                
                // 月份滾輪
                Picker("Month", selection: $selectedMonth) {
                    ForEach(months, id: \.self) { month in
                        Text("\(month)月").tag(month)
                    }
                }
                .pickerStyle(.wheel)
            }
            // 使用你的主題色點綴
            .background(Color(hex: "#DADADA").opacity(0.01))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 10)
    }
}
// MARK: - 編輯日記列表
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

// 顏色 Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(.sRGB, red: Double((int >> 16) & 0xff) / 255, green: Double((int >> 8) & 0xff) / 255, blue: Double(int & 0xff) / 255, opacity: 1)
    }
}

#Preview {
    Backpack()
}




