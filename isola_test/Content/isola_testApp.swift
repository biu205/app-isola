//
//  isola_testApp.swift
//  isola_test
//
//  Created by Biu on 2026/3/30.
//

import SwiftUI
import SwiftData

@main
struct isola_testApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppTheme.system.rawValue

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appearanceMode) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(selectedTheme.colorScheme)
        }
        .modelContainer(for: DiaryEntry.self)
    }
}

