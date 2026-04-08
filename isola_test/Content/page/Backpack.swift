import SwiftUI
import SwiftData

struct Backpack: View {
    @State private var currentMonth: Date = Date()
    // 新增：控制選擇器彈出的狀態
    @State private var showDatePicker = false
    
    // 新增：用於選擇器內部的暫存狀態
    @State private var selectedYear: Int = 2026
    @State private var selectedMonth: Int = 4
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            dynamicYearHeader
                .padding(.top, 40)
                .padding(.bottom, 10)
            
            monthHeader
                .padding(.top, 0)
                .padding(.bottom, 20)
            
            weekdayHeader
            
            calendarGrid
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color(hex: "#fafafa").ignoresSafeArea())
        // 核心功能：原生半屏選擇器
        .sheet(isPresented: $showDatePicker) {
            MonthYearPickerView(
                selectedYear: $selectedYear,
                selectedMonth: $selectedMonth,
                onConfirm: {
                    updateCurrentMonth()
                }
                

            )
            // 競賽加分亮點：完美控制半屏高度

            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
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
            
            // 核心優化：將文字改為按鈕，點擊開啟選擇器
            Button(action: {
                // 打開前，先將滾輪對齊目前的年月
                selectedYear = calendar.component(.year, from: currentMonth)
                selectedMonth = calendar.component(.month, from: currentMonth)
                showDatePicker = true
            }) {
                Text(monthString(from: currentMonth))
                    .font(.system(size: 32, weight: .medium, design: .serif))
                    .tracking(4)
                    .foregroundColor(.black)
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
    let years = Array(2015...2035)
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
            .background(Color(hex: "#FDF9E7").opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 10)
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
