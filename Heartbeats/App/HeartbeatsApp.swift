import SwiftUI

@main
struct HeartbeatsApp: App {
    @StateObject private var firebaseService = FirebaseService.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(firebaseService)
                .onAppear {
                    // Initialize Firebase on app launch
                    firebaseService.configure()
                }
        }
    }
}
