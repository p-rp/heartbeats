//
//  ContentView.swift
//  heartbeats Watch App
//
//  Created by Piyush on 2026-03-01.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        Group {
            if appState.isPaired {
                MainView()
            } else {
                SetupView()
            }
        }
        .environmentObject(appState)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
