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
    @State private var heartScale: CGFloat = 1.0
    @State private var heartScale2: CGFloat = 1.0
    @State private var linePhase: CGFloat = 0.0
    @State private var lineOpacity: CGFloat = 0.0
    
    var body: some View {
        VStack(spacing: 8) {
                // Two hearts with electric connection
                HStack(spacing: 0) {
                    // Left heart
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(heartScale)
                        .shadow(color: .red.opacity(0.5), radius: heartScale * 4)
                    
                    // Flowing blue connection line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white, .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: -60 + linePhase * 120)
                        )
                        .opacity(0.8)
                        .frame(height: 3)
                    
                    // Right heart
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(heartScale2)
                        .shadow(color: .red.opacity(0.5), radius: heartScale2 * 4)
                }
                .padding(.top, 0)
                
                Text("Connect Hearts")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Pair with someone")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                // Generate code button
                Button(action: { showingGenerateCode = true }) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("Generate Code")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
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
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
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
        .padding(.horizontal, 6)
        .background(Color.black)
        .sheet(isPresented: $showingGenerateCode) {
            GenerateCodeView()
        }
        .sheet(isPresented: $showingEnterCode) {
            EnterCodeView()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Heart 1 animation - pulse
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            heartScale = 1.15
        }
        
        // Heart 2 animation - beat together with heart 1
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            heartScale2 = 1.2
        }
        
        // Flowing line animation
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            linePhase = 5.0
        }
    }
}

#Preview {
    SetupView()
        .environmentObject(AppState())
}
