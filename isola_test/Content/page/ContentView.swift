import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // 設定第一頁為首頁的呈現
            
            HomeView()
                .tabItem {
                    Image("Home")
                    Text("首頁")
                }
            // 第二個標籤
            Backpack()
                .tabItem {
                    Image("Backpack")
                    Text("背包")
                }
            
            // 第三個標籤
            First_aid_Kit()
                .tabItem {
                    Image("First_Aid_Kit")
                    Text("急救箱")
                }
            
            // 第四個標籤 (HRV)
            HRV()
                .tabItem {
                    Image("Month_Report")
                    Text("月報")
                }
        }
        .accentColor(Color.brown)
    }
}


#Preview {
    ContentView()
}
