import SwiftUI
import SwiftData
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
      NavigationStack {
        ContentView()
      }
    }
    .modelContainer(for: [DiaryEntry.self, JournalQuestion.self, DiaryMedia.self])
  }
}

struct ContentView: View {
    @State private var lockManager = AppLockManager.shared
    @State private var healthVM = HealthDashboardViewModel()
    @AppStorage("bottleAnsweredDate") private var bottleAnsweredDateStr: String = ""

    private static let todayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var isAnsweredToday: Bool {
        bottleAnsweredDateStr == Self.todayFormatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            TabView {
                HomeView()
                    .tabItem {
                        Image("Home")
                        Text("首頁")
                    }
                Backpack()
                    .tabItem {
                        Image("Backpack")
                        Text("背包")
                    }
                HealthHomeView()
                    .environment(healthVM)
                    .tabItem {
                        Image("First_Aid_Kit")
                        Text("健康")
                    }
                MoodReportView()
                    .environment(healthVM)
                    .tabItem {
                        Image("Month_Report")
                        Text("週報")
                    }
            }
            .accentColor(Color.brown)

            if lockManager.isLocked {
                AppLockUnlockView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: lockManager.isLocked)
        .task {
            healthVM.requestAuthorization()
            await NotificationManager.shared.requestPermission()
            NotificationManager.shared.scheduleJournalReminders(answeredToday: isAnsweredToday)
        }
    }
}


#Preview {
    ContentView()
}
