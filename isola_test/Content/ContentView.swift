import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView{
            // 設定第一頁為首頁的呈現
            HomeView()
                .tabItem {
                    Image(systemName: "apple.meditate")
                    Text("首頁")
                }
            // 第二個標籤
            Backpack()
                .tabItem {
                    Image(systemName: "bookmark")
                    Text("背包")
                }
             
            // 第三個標籤
            First_aid_Kit()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("急救箱")
                }
            HRV()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("月報")
                }
        }
    }
}

#Preview {
    ContentView()
}
