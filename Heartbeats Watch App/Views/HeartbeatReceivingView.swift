import SwiftUI

/// View for when the user is receiving someone else's heartbeat
struct HeartbeatReceivingView: View {
    @EnvironmentObject var viewModel: HeartbeatViewModel
    @EnvironmentObject var hapticManager: HapticManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status indicator
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .opacity(isAnimating ? 1 : 0.3)
                        .animation(.easeInOut(duration: 0.8).repeatForever(), value: isAnimating)

                    Text("Feeling Heartbeat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // Heart animation synced to received BPM
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6 / max((viewModel.currentBPM / 60), 0.5)).repeatForever(autoreverses: true), value: isAnimating)

                    Image(systemName: "heart.beat.2.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.6 / max((viewModel.currentBPM / 60), 0.5)).repeatForever(autoreverses: true), value: isAnimating)
                }
                .padding()

                // Received BPM display
                VStack(spacing: 5) {
                    Text("\(Int(viewModel.currentBPM))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)

                    Text("BPM")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()

                // Duration timer
                Text("\(Int(viewModel.sessionDuration))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())

                // Connection quality indicator
                HStack(spacing: 5) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index < signalStrength ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 5)

                Divider()

                // Stop button
                Button {
                    withAnimation {
                        viewModel.stopReceiving()
                    }
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Stop Feeling")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding()
        }
        .onAppear {
            isAnimating = true
        }
        .onDisappear {
            isAnimating = false
            hapticManager.stopHeartbeat()
        }
    }

    @State private var isAnimating = false
    @State private var signalStrength = 3
}

#Preview {
    HeartbeatReceivingView()
        .environmentObject(HeartbeatViewModel.shared)
        .environmentObject(HapticManager.shared)
}
