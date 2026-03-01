import SwiftUI

/// View for when the user is streaming their heartbeat
struct HeartbeatStreamingView: View {
    @EnvironmentObject var viewModel: HeartbeatViewModel
    @EnvironmentObject var heartRateManager: HeartRateManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status indicator
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .opacity(isAnimating ? 1 : 0.3)
                        .animation(.easeInOut(duration: 0.8).repeatForever(), value: isAnimating)

                    Text("Sharing Heartbeat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // Heart animation
                ZStack {
                    Circle()
                        .stroke(Color.red.opacity(0.2), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6 / max((viewModel.currentBPM / 60), 0.5)).repeatForever(autoreverses: true), value: isAnimating)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.6 / max((viewModel.currentBPM / 60), 0.5)).repeatForever(autoreverses: true), value: isAnimating)
                }
                .padding()

                // Current BPM display
                VStack(spacing: 5) {
                    Text("\(Int(viewModel.currentBPM))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.red)

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

                Divider()

                // Stop button
                Button {
                    withAnimation {
                        viewModel.stopStreaming()
                    }
                } label: {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Sharing")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
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
        }
    }

    @State private var isAnimating = false
}

#Preview {
    HeartbeatStreamingView()
        .environmentObject(HeartbeatViewModel.shared)
        .environmentObject(HeartRateManager.shared)
}
