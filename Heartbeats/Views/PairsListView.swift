import SwiftUI

/// View showing all paired users
struct PairsListView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var showDeleteAlert = false
    @State private var userToDelete: PairedUser?

    var body: some View {
        NavigationView {
            ZStack {
                if firebaseService.pairedUsers.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No Pairs Yet")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Pair with someone to start sharing heartbeats")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        NavigationLink(destination: PairingView()) {
                            Text("Add First Pair")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    .padding()
                } else {
                    // List of paired users
                    List {
                        ForEach(firebaseService.pairedUsers) { user in
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(user.name)
                                        .font(.headline)

                                    Text("Connected \(user.pairedAt, style: .relative) ago")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button {
                                    sendHeartbeatRequest(to: user)
                                } label: {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                }
                            }
                            .padding(.vertical, 8)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    userToDelete = user
                                    showDeleteAlert = true
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Pairs")
            .overlay(alignment: .bottomTrailing) {
                if !firebaseService.pairedUsers.isEmpty {
                    NavigationLink(destination: PairingView()) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
            .alert("Remove Pair", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    if let user = userToDelete {
                        firebaseService.removePairedUser(user)
                    }
                }
            } message: {
                Text("Are you sure you want to remove this pair?")
            }
        }
    }

    // MARK: - Methods
    private func sendHeartbeatRequest(to user: PairedUser) {
        // Send request via WatchConnectivityManager
        WatchConnectivityManager.shared.sendHeartbeatRequest(to: user.id, userName: user.name)

        // Also notify via Firebase
        Task {
            _ = await firebaseService.createSession(
                senderId: firebaseService.getCurrentUserId(),
                receiverId: user.id,
                duration: 60
            )
        }
    }
}

#Preview {
    PairsListView()
        .environmentObject(FirebaseService.shared)
}
