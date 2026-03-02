//
//  EnterCodeView.swift
//  heartbeats Watch App
//
//  Screen for entering pairing code
//

import SwiftUI

struct EnterCodeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var code: String = ""
    @State private var isSearching = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                Text("Enter Code")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                // Code input field
                VStack(spacing: 8) {
                    TextField("BEAT-XXXX", text: $code)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .onChange(of: code) { newValue in
                            // Auto-format to BEAT-XXXX
                            let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                            if filtered.count > 8 {
                                code = String(filtered.prefix(8))
                            } else {
                                code = filtered
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                        )
                    
                    Text("Enter your partner's code")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Search button
                Button(action: searchForCode) {
                    if isSearching {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Find Partner")
                            .font(.headline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            code.count >= 4 ?
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [.gray, .gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .disabled(code.count < 4 || isSearching)
                .buttonStyle(PlainButtonStyle())
                
                // Error message
                if showError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.2))
                    )
                }
                
                Spacer()
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.cyan)
                        Text("Ask your partner for their code")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.blue)
                        Text("Enter it above")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.purple)
                        Text("You're connected forever!")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .background(Color.black)
    }
    
    private func searchForCode() {
        isSearching = true
        showError = false
        
        Task {
            do {
                // First, ensure we have a user ID
                var userId = FirebaseManager.shared.getCurrentUserId()
                if userId == nil {
                    userId = try await FirebaseManager.shared.signInAnonymously()
                }
                
                // Search for the pairing code
                if let found = try await PairingService.shared.findPairing(byCode: code) {
                    // Complete the pairing
                    try await PairingService.shared.completePairing(userA: userId!, userB: found.userId)
                    
                    await MainActor.run {
                        appState.savePairing(partnerId: found.userId, partnerName: "Partner")
                        isSearching = false
                        dismiss()
                    }
                } else {
                    await MainActor.run {
                        isSearching = false
                        showError = true
                        errorMessage = "Code not found. Make sure you entered it correctly."
                    }
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    showError = true
                    errorMessage = "Connection error. Please try again."
                }
            }
        }
    }
}

#Preview {
    EnterCodeView()
        .environmentObject(AppState())
}
