import SwiftUI
import Observation

//關掉nav的開關！
@Observable
class UIManager {
    var isTabBarVisible: Bool = true
}

struct ContentView: View {
    @State private var uiManager = UIManager()
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
        .toolbar(uiManager.isTabBarVisible ? .visible : .hidden, for: .tabBar)
        .environment(uiManager)
        
    }
}


#Preview {
    ContentView()
}
