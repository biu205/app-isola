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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: DiaryEntry.self)
    }
}

