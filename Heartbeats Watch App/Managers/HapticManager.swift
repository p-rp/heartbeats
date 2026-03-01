import Foundation
import CoreHaptics

/// Manages haptic feedback for heartbeat simulation
class HapticManager: ObservableObject {
    static let shared = HapticManager()

    // MARK: - Properties
    private var hapticEngine: CHHapticEngine?
    private var heartbeatTimer: Timer?
    private var currentBPM: Double = 60
    @Published var isPlaying = false

    private init() {
        prepareHapticEngine()
    }

    // MARK: - Engine Preparation
    private func prepareHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptics not supported on this device")
            return
        }

        do {
            hapticEngine = try CHHapticEngine()

            // Handle engine restart
            hapticEngine?.resetHandler = { [weak self] in
                self?.startEngine()
            }

            hapticEngine?.stoppedHandler = { reason, error in
                print("Haptic engine stopped: \(reason)")
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }

            try hapticEngine?.start()
        } catch {
            print("Failed to create haptic engine: \(error.localizedDescription)")
        }
    }

    private func startEngine() {
        do {
            try hapticEngine?.start()
        } catch {
            print("Failed to restart haptic engine: \(error.localizedDescription)")
        }
    }

    // MARK: - Heartbeat Pattern
    /// Plays a heartbeat haptic pattern synchronized to BPM
    func playHeartbeatPattern(bpm: Double) {
        self.currentBPM = bpm
        isPlaying = true

        // Stop any existing timer
        stopHeartbeat()

        // Calculate interval between beats (in seconds)
        let beatInterval = 60.0 / bpm

        // Create timer for repeating heartbeat
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: beatInterval, repeats: true) { [weak self] _ in
            self?.playSingleHeartbeat()
        }

        // Play first beat immediately
        playSingleHeartbeat()
    }

    /// Stops the heartbeat haptic pattern
    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        isPlaying = false
    }

    /// Plays a single heartbeat haptic (two sharp taps like a real heartbeat)
    private func playSingleHeartbeat() {
        guard let engine = hapticEngine else {
            playBasicHeartbeat()
            return
        }

        // Create heartbeat pattern: lub-dub (two beats close together)
        let intensity = 1.0
        let sharpness = 0.8

        do {
            // First beat (lub)
            let firstEvent = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )

            // Second beat (dub) - slightly weaker and delayed
            let secondEvent = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness * 0.6)
                ],
                relativeTime: 0.15 // 150ms delay for the second beat
            )

            let pattern = try CHHapticPattern(events: [firstEvent, secondEvent], parameters: [])

            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play heartbeat haptic: \(error.localizedDescription)")
            playBasicHeartbeat()
        }
    }

    /// Fallback basic heartbeat using UINotificationFeedbackGenerator
    private func playBasicHeartbeat() {
        // First beat
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Second beat (slightly delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let secondGenerator = UINotificationFeedbackGenerator()
            secondGenerator.notificationOccurred(.success)
        }
    }

    // MARK: - Other Haptics
    /// Plays a haptic for connection successful
    func playConnectionSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Plays a haptic for error
    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Plays a haptic for heartbeat request received
    func playHeartbeatRequest() {
        // Double tap pattern
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let secondGenerator = UIImpactFeedbackGenerator(style: .medium)
            secondGenerator.impactOccurred()
        }
    }

    /// Plays a gentle tick for each BPM received
    func playTick() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
