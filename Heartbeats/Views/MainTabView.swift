import SwiftUI

/// Main tab view for the iOS app
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PairsListView()
                .tabItem {
                    Image(systemName: "heart.circle.fill")
                    Text("Pairs")
                }
                .tag(0)

            PairingView()
                .tabItem {
                    Image(systemName: "person.badge.plus")
                    Text("Pair")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.red)
    }
}

/// Settings view for Firebase configuration
struct SettingsView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var databaseURL: String = ""
    @State private var databaseSecret: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Firebase Configuration")) {
                    Text("To use this app, create a free Firebase project at firebase.google.com")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Database URL", text: $databaseURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("Database Secret (Optional)", text: $databaseSecret)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Section(header: Text("Your Info")) {
                    HStack {
                        Text("User ID")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(firebaseService.getCurrentUserId())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button("Get Connection Code") {
                        Task {
                            let code = await firebaseService.getOrGenerateConnectionCode()
                            alertMessage = "Share this code with your partner: \(code)"
                            showAlert = true
                        }
                    }
                }

                Section {
                    Button("Save Configuration") {
                        firebaseService.setCustomConfig(url: databaseURL, secret: databaseSecret.isEmpty ? nil : databaseSecret)
                        alertMessage = "Configuration saved!"
                        showAlert = true
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color.red)
                }
            }
            .navigationTitle("Settings")
            .alert("Info", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}
