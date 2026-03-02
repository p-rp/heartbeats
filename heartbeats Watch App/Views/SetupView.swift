//
//  SetupView.swift
//  heartbeats Watch App
//
//  Pairing setup screen with playful UI
//

import SwiftUI

struct SetupView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingGenerateCode = false
    @State private var showingEnterCode = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Heart icon
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse)
                    .padding(.top, 8)
                
                Text("Connect Hearts")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Pair with someone to feel their heartbeat")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Spacer(minLength: 8)
                
                // Generate code button
                Button(action: { showingGenerateCode = true }) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("Generate Code")
                    }
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
                
                // Enter code button
                Button(action: { showingEnterCode = true }) {
                    HStack {
                        Image(systemName: "number.square")
                        Text("Enter Code")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
        }
        .background(Color.black)
        .sheet(isPresented: $showingGenerateCode) {
            GenerateCodeView()
        }
        .sheet(isPresented: $showingEnterCode) {
            EnterCodeView()
        }
    }
}

#Preview {
    SetupView()
        .environmentObject(AppState())
}
