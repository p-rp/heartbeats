//
//  MainView.swift
//  heartbeats Watch App
//
//  Main screen after pairing - dark mode with playful UI
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingRequestHeartbeat = false
    @State private var partnerStatus: PartnerStatus = .offline
    @State private var showingRenameAlert = false
    @State private var newPartnerName = ""
    
    enum PartnerStatus {
        case online
        case offline
        case unknown
        
        var color: Color {
            switch self {
            case .online: return .green
            case .offline: return .gray
            case .unknown: return .orange
            }
        }
        
        var text: String {
            switch self {
            case .online: return "Online"
            case .offline: return "Offline"
            case .unknown: return "Checking..."
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Partner info card
                VStack(spacing: 12) {
                    // Status indicator
                    HStack {
                        Circle()
                            .fill(partnerStatus.color)
                            .frame(width: 8, height: 8)
                        
                        Text(partnerStatus.text)
                            .font(.caption)
                            .foregroundColor(partnerStatus.color)
                        
                        Spacer()
                    }
                    
                    // Partner name
                    Button(action: {
                        newPartnerName = appState.partnerName ?? "Partner"
                        showingRenameAlert = true
                    }) {
                        Text(appState.partnerName ?? "Partner")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Heart animation
                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse)
                        .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.15))
                )
                
                // Request heartbeat button
                Button(action: { showingRequestHeartbeat = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Feel Heartbeat")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Request 10 seconds of their heartbeat")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.pink.opacity(0.15),
                                        Color.purple.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.pink.opacity(0.5), .purple.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Settings button
                Button(action: {}) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.gray)
                        Text("Settings")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(Color.black)
        .onAppear {
            // TODO: Check partner status from Firebase
            // This will be implemented in Phase 2.5
            checkPartnerStatus()
        }
        .alert("Rename Partner", isPresented: $showingRenameAlert) {
            TextField("Name", text: $newPartnerName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if !newPartnerName.isEmpty {
                    appState.updatePartnerName(newPartnerName)
                }
            }
        }
    }
    
    private func checkPartnerStatus() {
        // Placeholder - will check Firebase in later phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            partnerStatus = .online
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AppState())
}
