//
//  heartbeatsApp.swift
//  heartbeats Watch App
//
//  Created by Piyush on 2026-03-01.
//

import SwiftUI
import FirebaseCore

@main
struct heartbeats_Watch_AppApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
