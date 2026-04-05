//
//  First.swift
//  isola_test
//
//  Created by Qian Hsu on 2026/4/5.
//


import SwiftUI

struct HRV: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text("HRV")
                
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
