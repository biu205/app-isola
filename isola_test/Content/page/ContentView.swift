import SwiftUI
import FirebaseCore
// firebase!耶

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct YourApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}

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
            MoodReportView()
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
