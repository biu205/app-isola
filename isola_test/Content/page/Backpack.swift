import SwiftUI
import SwiftData

struct Backpack: View {
    @State private var currentMonth: Date = Date()
    @State private var showDatePicker = false
    @Environment(\.modelContext) private var modelContext
    @State private var selectedYear: Int = 2026
    @State private var selectedMonth: Int = 4
    @Query(sort: \DiaryEntry.date, order: .reverse) private var entries: [DiaryEntry]
    @State private var entryToEdit: DiaryEntry?

    let moodImages = ["非常不愉快度Ｑ1", "不愉快度Ｑ1", "度Ｑ1", "愉快度Ｑ1", "非常愉快度Ｑ1"]
    let moodNames = ["非常不愉快", "不愉快", "一般", "愉快", "非常愉快"]
    let emptyMoodImage = "空白沒寫度Ｑ"
    let futureMoodImage = "還沒到度Ｑ"
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)

// MARK: - 主視圖
    var body: some View {
        ZStack {
            // 背景色
            Color(hex: "#FFFCF1")
                .ignoresSafeArea()
            // 可滑動的頁面
            ScrollView {
                VStack(spacing: 0) {
                    dynamicYearHeader
                        .padding(.top, 40)
                        .padding(.bottom, 10)

                    monthHeader
                        .padding(.bottom, 20)

                    weekdayHeader

                    calendarGrid
                        .padding(.horizontal, 20)

                    diarySection
                        .padding(.top, 40)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
        }
        // 編輯日記的彈出式視窗
        .sheet(item: $entryToEdit) { entry in
            EditDiaryView(entry: entry)
        }
        // 年月選擇器的彈出式視窗
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

    // 刪除日記
    func deleteEntry(_ entry: DiaryEntry) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            withAnimation(.spring(response: 0.15, dampingFraction: 0.75)) {
                modelContext.delete(entry)
            }
        }
}

// MARK: - UI 組件拆分
// 日記列表
private extension Backpack {
    var diarySection: some View {
            Group {
                // 如果日記列表為空，顯示空白的提示
                if entries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "backpack.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("背包裡空空的")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("去海灘撿個瓶子寫下今天的心情吧！")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    // 如果日記列表不為空，顯示日記列表
                    LazyVStack(spacing: 12) {
                        ForEach(entries) { entry in
                            diaryRow(entry)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .scale(scale: 0.8, anchor: .center).combined(with: .opacity)
                                ))
                        }
                    }
                    // 動畫效果
                    .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: entries)
                }
            }
        }

    // 日記行
    func diaryRow(_ entry: DiaryEntry) -> some View {
        // 心情索引
        let moodIndex = max(0, min(4, entry.moodIndex))
        // 截斷內容
        let truncatedContent = entry.content.count > 10
            ? String(entry.content.prefix(10)) + "..."
            : entry.content

        return DiarySwipeRow(
            // 點擊日記行
            onTap: { entryToEdit = entry },
            // 刪除日記行
            onDelete: { deleteEntry(entry) }
        ) {
            // 心情圖片
            HStack(spacing: 16) {
                Image(moodImages[moodIndex])
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color.white.opacity(0.9)))

                // 日記標題和日期
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .lastTextBaseline) {
                        Text(entry.title)
                            .font(.system(.headline, design: .serif))
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Text(entry.date, format: .dateTime.month().day())
                            .font(.caption)
                            .foregroundColor(.gray)
                            .layoutPriority(1)
                    }.padding(.top,15)
                    Text(truncatedContent)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }.padding(.bottom,15)

                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
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
                let date = dateForDay(day, in: currentMonth)
                VStack(spacing: 8) {
                    Text("\(day)")
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(.black)
                    
                    Button {
                        openLatestEntry(for: date)
                    } label: {
                        Image(moodImageName(for: date))
                            .resizable()
                            .scaledToFit()
                            .frame(height: 45)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct DiarySwipeRow<Content: View>: View {
    let onTap: () -> Void
    let onDelete: () -> Void
    @ViewBuilder var content: Content

    @State private var offsetX: CGFloat = 0
    @State private var isDraggingRow = false
    @State private var isDeleting = false
    private let revealWidth: CGFloat = 76

    var body: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.9))
                .overlay(alignment: .trailing) {
                    Button(action: handleDeleteTap) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 18)
                    .opacity(offsetX < -10 ? 1 : 0)
                    .scaleEffect(offsetX <= -revealWidth + 2 ? 1.06 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.85), value: offsetX)
                }

            content
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.08), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                .contentShape(RoundedRectangle(cornerRadius: 16))
                .opacity(isDeleting ? 0 : 1)
                .scaleEffect(isDeleting ? 0.94 : 1)
                .onTapGesture {
                    if offsetX < 0 {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                            offsetX = 0
                        }
                        return
                    }
                    if !isDraggingRow {
                        onTap()
                    }
                }
                .offset(x: offsetX)
                .gesture(
                    DragGesture(minimumDistance: 30)
                            .onChanged { value in
                                // 💡 修改 2：核心關鍵，判斷如果是上下滑動（垂直位移 > 水平位移），就直接 return 不處理
                                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                
                                isDraggingRow = true
                                let translation = value.translation.width
                                
                                if translation < 0 {
                                    offsetX = max(-revealWidth, translation)
                                } else if offsetX < 0 {
                                    offsetX = min(0, -revealWidth + translation)
                                }
                            }
                            .onEnded { value in
                                // 💡 修改 3：確保只有在真正執行了橫向拖曳後，才觸發收合或展開邏輯
                                guard isDraggingRow else { return }
                                
                                let projected = value.predictedEndTranslation.width
                                let shouldOpen = value.translation.width < -revealWidth * 0.35 || projected < -revealWidth * 0.7
                                
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                                    offsetX = shouldOpen ? -revealWidth : 0
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    isDraggingRow = false
                                }
                            }
                    )
                    .animation(.easeOut(duration: 0.16), value: isDeleting)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func handleDeleteTap() {
        guard !isDeleting else { return }
        withAnimation(.easeInOut(duration: 0.16)) {
            isDeleting = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            onDelete()
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

    func dateForDay(_ day: Int, in month: Date) -> Date {
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = day
        return calendar.date(from: components) ?? month
    }

    func moodImageName(for date: Date) -> String {
        let targetDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())

        if targetDay > today {
            return futureMoodImage
        }

        let dayEntries = entries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: targetDay)
        }

        guard !dayEntries.isEmpty else {
            return emptyMoodImage
        }

        let totalMood = dayEntries.reduce(0) { $0 + $1.moodIndex }
        let averageMood = Double(totalMood) / Double(dayEntries.count)
        let roundedMoodIndex = Int(averageMood.rounded())
        let safeMoodIndex = max(0, min(moodImages.count - 1, roundedMoodIndex))
        return moodImages[safeMoodIndex]
    }

    func openLatestEntry(for date: Date) {
        let targetDay = calendar.startOfDay(for: date)
        let dayEntries = entries
            .filter { entry in
                calendar.isDate(entry.date, inSameDayAs: targetDay)
            }
            .sorted { $0.date > $1.date }

        guard let latestEntry = dayEntries.first else { return }
        entryToEdit = latestEntry
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
    
    // 預設年份範圍
    let years = Array(2026...2099)
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




