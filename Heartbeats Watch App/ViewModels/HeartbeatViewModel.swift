import Foundation
import Combine
import WatchConnectivity

/// ViewModel for managing heartbeat sessions on the watch
class HeartbeatViewModel: ObservableObject {
    static let shared = HeartbeatViewModel()

    // MARK: - Published Properties
    @Published var appState: AppState = .idle
    @Published var currentBPM: Double = 0
    @Published var sessionDuration: TimeInterval = 0
    @Published var isSimulated: Bool = false

    // MARK: - Private Properties
    private var sessionTimer: Timer?
    private var bpmUpdateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let sessionDurationDefault: TimeInterval = 60

    enum AppState {
        case idle
        case streaming
        case receiving
    }

    private init() {
        setupWatchConnectivity()
    }

    // MARK: - Watch Connectivity
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Streaming
    func startStreaming(isSimulated: Bool = false) {
        self.isSimulated = isSimulated
        appState = .streaming
        sessionDuration = 0

        // Start session timer
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.sessionDuration += 1

            // Auto-stop after default duration
            if self?.sessionDuration ?? 0 >= self?.sessionDurationDefault ?? 60 {
                self?.stopStreaming()
            }
        }

        // Notify iPhone that we started streaming
        notifyPhoneStreamingStarted()

        // Start heart rate updates
        if isSimulated {
            HeartRateManager.shared.startSimulatedHeartRate { [weak self] bpm in
                self?.currentBPM = bpm
                self?.sendBPMToPhone(bpm)
            }
        } else {
            Task {
                do {
                    try await HeartRateManager.shared.requestAuthorization()
                    try await HeartRateManager.shared.startHeartRateUpdates { [weak self] bpm in
                        self?.currentBPM = bpm
                        self?.sendBPMToPhone(bpm)
                    }
                } catch {
                    print("Error starting heart rate updates: \(error)")
                    // Fall back to simulated
                    HeartRateManager.shared.startSimulatedHeartRate { [weak self] bpm in
                        self?.currentBPM = bpm
                        self?.sendBPMToPhone(bpm)
                    }
                    self?.isSimulated = true
                }
            }
        }
    }

    func stopStreaming() {
        appState = .idle
        sessionTimer?.invalidate()
        sessionTimer = nil
        bpmUpdateTimer?.invalidate()
        bpmUpdateTimer = nil
        sessionDuration = 0
        currentBPM = 0

        HeartRateManager.shared.stopUpdates()
        notifyPhoneStreamingStopped()
    }

    // MARK: - Receiving
    func startReceiving() {
        appState = .receiving
        sessionDuration = 0
        currentBPM = 0

        // Start listening for BPM from phone
        startListeningForBPM()

        // Start session timer
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.sessionDuration += 1
        }
    }

    func stopReceiving() {
        appState = .idle
        sessionTimer?.invalidate()
        sessionTimer = nil
        bpmUpdateTimer?.invalidate()
        bpmUpdateTimer = nil
        sessionDuration = 0
        currentBPM = 0

        HapticManager.shared.stopHeartbeat()
    }

    // MARK: - BPM Handling
    private func sendBPMToPhone(_ bpm: Double) {
        let message: [String: Any] = [
            "type": "bpmUpdate",
            "bpm": bpm,
            "timestamp": Date().timeIntervalSince1970
        ]

        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    private func startListeningForBPM() {
        // This would listen to Firebase via phone relay
        // For now, we'll use a timer to simulate incoming BPM
        bpmUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // In production, this would get real BPM from Firebase
            // Simulated for now
            let simulatedBPM = Double.random(in: 65...95)
            self?.handleReceivedBPM(simulatedBPM)
        }
    }

    private func handleReceivedBPM(_ bpm: Double) {
        currentBPM = bpm
        HapticManager.shared.playHeartbeatPattern(bpm: bpm)
    }

    // MARK: - Phone Communication
    private func notifyPhoneStreamingStarted() {
        let message: [String: Any] = ["type": "streamingStarted"]
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    private func notifyPhoneStreamingStopped() {
        let message: [String: Any] = ["type": "streamingStopped"]
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
}

// MARK: - WCSessionDelegate
extension HeartbeatViewModel: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation error: \(error.localizedDescription)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        DispatchQueue.main.async { [weak self] in
            switch type {
            case "startStreaming":
                if let receiverId = message["receiverId"] as? String {
                    // Start streaming to this receiver
                    self?.startStreaming(isSimulated: false)
                }

            case "stopStreaming":
                self?.stopStreaming()

            case "heartbeatData":
                if let bpm = message["bpm"] as? Double {
                    self?.handleReceivedBPM(bpm)
                }

            case "heartbeatRequest":
                // Show notification of incoming request
                HapticManager.shared.playHeartbeatRequest()

            default:
                break
            }
        }
    }
}
