//
//  First_aid_Kit.swift
//  isola_test
//
//  Created by Qian Hsu on 2026/4/5.
//

import SwiftUI

struct First_aid_Kit: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text("First_aid_Kit")
                
                    .font(.largeTitle)
                    .bold()
                Text("Coming Soon...")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
