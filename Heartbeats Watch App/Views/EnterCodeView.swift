//
//  EnterCodeView.swift
//  heartbeats Watch App
//
//  Screen for entering pairing code with numpad
//

import SwiftUI

struct EnterCodeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var code: String = ""
    @State private var isSearching = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 2) {
            // Code display
            Text(code.isEmpty ? "------" : formatCode(code))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(4)
                .frame(height: 28)
                .animation(.easeInOut(duration: 0.1), value: code)
            
            // Numpad
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(1...9, id: \.self) { number in
                    Button(action: { addDigit(String(number)) }) {
                        Text("\(number)")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(code.count >= 6 || isSearching)
                }
                
                // Delete button
                Button(action: { deleteDigit() }) {
                    Image(systemName: "delete.left.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(code.isEmpty || isSearching)
                
                // Zero
                Button(action: { addDigit("0") }) {
                    Text("0")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(code.count >= 6 || isSearching)
                
                // Enter button
                Button(action: searchForCode) {
                    if isSearching {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    Circle()
                        .fill(
                            code.count == 6 ?
                            LinearGradient(
                                colors: [.green, .cyan],
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
                .buttonStyle(PlainButtonStyle())
                .disabled(code.count != 6 || isSearching)
            }
            .padding(.horizontal, 4)
            
            // Error message
            if showError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.black)
    }
    
    private func formatCode(_ code: String) -> String {
        let padded = code.padding(toLength: 6, withPad: "-", startingAt: 0)
        return padded
    }
    
    private func addDigit(_ digit: String) {
        guard code.count < 6 else { return }
        code += digit
    }
    
    private func deleteDigit() {
        guard !code.isEmpty else { return }
        code.removeLast()
    }
    
    private func searchForCode() {
        guard code.count == 6 else { return }
        
        isSearching = true
        showError = false
        
        Task {
            do {
                var userId = FirebaseManager.shared.getCurrentUserId()
                if userId == nil {
                    userId = try await FirebaseManager.shared.signInAnonymously()
                }
                
                if let found = try await PairingService.shared.findPairing(byCode: code) {
                    try await PairingService.shared.completePairing(userA: userId!, userB: found.userId)
                    
                    await MainActor.run {
                        appState.savePairing(partnerId: found.userId, partnerName: "Partner")
                        isSearching = false
                        dismiss()
                    }
                    await MainActor.run {
                        isSearching = false
                        showError = true
                        errorMessage = "Code not found"
                    }
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    showError = true
                    errorMessage = "Connection error"
                }
            }
        }
    }
}

#Preview {
    EnterCodeView()
        .environmentObject(AppState())
}
