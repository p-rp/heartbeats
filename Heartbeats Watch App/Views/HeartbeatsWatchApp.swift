import SwiftUI

@main
struct HeartbeatsWatchApp: App {
    @StateObject private var heartRateManager = HeartRateManager()
    @StateObject private var hapticManager = HapticManager()
    @StateObject private var heartbeatViewModel = HeartbeatViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(heartRateManager)
                .environmentObject(hapticManager)
                .environmentObject(heartbeatViewModel)
        }
    }
}

/// Main content view for the watch app
struct ContentView: View {
    @EnvironmentObject var viewModel: HeartbeatViewModel

    var body: some View {
        Group {
            switch viewModel.appState {
            case .idle:
                IdleView()
            case .streaming:
                HeartbeatStreamingView()
            case .receiving:
                HeartbeatReceivingView()
            }
        }
    }
}

/// Idle view showing options to start or receive heartbeat
struct IdleView: View {
    @EnvironmentObject var viewModel: HeartbeatViewModel
    @EnvironmentObject var heartRateManager: HeartRateManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "heart.beat.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)

                Text("Heartbeats")
                    .font(.headline)

                Divider()

                Button {
                    viewModel.startStreaming()
                } label: {
                    VStack {
                        Image(systemName: "heart.circle.fill")
                            .font(.title2)
                        Text("Share My Heartbeat")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(15)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.startReceiving()
                } label: {
                    VStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.title2)
                        Text("Feel Heartbeat")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(15)
                }
                .buttonStyle(.plain)

                Spacer()

                // Current heart rate reading
                if heartRateManager.currentHeartRate > 0 {
                    VStack {
                        Text("\(Int(heartRateManager.currentHeartRate))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.red)
                        Text("BPM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                }
            }
            .padding()
        }
    }
}
