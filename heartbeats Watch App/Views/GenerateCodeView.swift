//
//  GenerateCodeView.swift
//  heartbeats Watch App
//
//  Screen for generating pairing code
//

import SwiftUI

struct GenerateCodeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var generatedCode: String = ""
    @State private var isGenerating = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Your Code")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Code display
                if generatedCode.isEmpty {
                    Button(action: generateCode) {
                        VStack(spacing: 8) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.pink, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Generate Code")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    VStack(spacing: 12) {
                        Text(generatedCode)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .tracking(2)
                        
                        Text("Share this code with your partner")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.2))
                    )
                }
                
                // Instructions
                if !generatedCode.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.pink)
                            Text("Give this code to your partner")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(.purple)
                            Text("They enter it on their watch")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(.cyan)
                            Text("You're connected forever!")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
                
                // Done button
                if !generatedCode.isEmpty {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [.pink, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(Color.black)
    }
    
    private func generateCode() {
        isGenerating = true
        
        Task {
            do {
                // First, ensure we have a user ID
                var userId = FirebaseManager.shared.getCurrentUserId()
                if userId == nil {
                    userId = try await FirebaseManager.shared.signInAnonymously()
                }
                
                // Create pairing code in Firebase
                let code = try await PairingService.shared.createPairingCode(for: userId!)
                
                await MainActor.run {
                    generatedCode = code
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    generatedCode = CodeGenerator.generatePairingCode()
                }
            }
        }
    }
}

#Preview {
    GenerateCodeView()
        .environmentObject(AppState())
}
