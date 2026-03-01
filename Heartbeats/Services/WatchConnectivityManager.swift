import Foundation
import WatchConnectivity
import Combine

// MARK: - Watch Connectivity Manager
/// Handles communication between iOS app and watchOS app via WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    // MARK: - Published Properties
    @Published var isWatchPaired = false
    @Published var isWatchAppInstalled = false
    @Published var isReachable = false
    @Published var pairedUsersOnWatch: [PairedUser] = []

    // MARK: - Private Properties
    private var session: WCSession? {
        didSet {
            oldValue?.delegate = nil
            session?.delegate = self
        }
    }

    private var cancellables = Set<AnyCancellable>()

    // Callbacks for heartbeat requests
    var onHeartbeatRequestReceived: ((String) -> Void)?
    var onHeartbeatRequestAccepted: (() -> Void)?
    var onHeartbeatRequestDeclined: (() -> Void)?

    private override init() {
        super.init()
        activateSession()
    }

    // MARK: - Session Activation
    private func activateSession() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity is not supported on this device")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable

            if let error = error {
                print("WCSession activation error: \(error.localizedDescription)")
            } else {
                print("WCSession activated with state: \(activationState.rawValue)")
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = false
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = false
        }
        // Reactivate session
        self.session?.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    // MARK: - Sending Data to Watch
    /// Sync paired users to the watch
    func syncPairedUsers(_ users: [PairedUser]) {
        guard let session = session, session.isReachable else {
            print("Watch is not reachable")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(users)

            let userData = ["pairedUsers": data]

            session.transferUserInfo(userData)
            print("Synced \(users.count) paired users to watch")
        } catch {
            print("Error encoding paired users: \(error)")
        }
    }

    /// Send heartbeat request to watch
    func sendHeartbeatRequest(to userId: String, userName: String) {
        guard let session = session, session.isReachable else {
            print("Watch is not reachable")
            return
        }

        let requestData: [String: Any] = [
            "type": "heartbeatRequest",
            "userId": userId,
            "userName": userName,
            "timestamp": Date().timeIntervalSince1970
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: requestData)
            if let message = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                    print("Error sending heartbeat request: \(error.localizedDescription)")
                })
            }
        } catch {
            print("Error serializing heartbeat request: \(error)")
        }
    }

    /// Send start streaming command to watch
    func sendStartStreaming(to sessionId: String, receiverId: String) {
        guard let session = session, session.isReachable else {
            print("Watch is not reachable")
            return
        }

        let command: [String: Any] = [
            "type": "startStreaming",
            "sessionId": sessionId,
            "receiverId": receiverId
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: command)
            if let message = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                    print("Error sending start streaming: \(error.localizedDescription)")
                })
            }
        } catch {
            print("Error serializing start streaming: \(error)")
        }
    }

    /// Send stop streaming command to watch
    func sendStopStreaming() {
        guard let session = session, session.isReachable else {
            print("Watch is not reachable")
            return
        }

        let command: [String: Any] = ["type": "stopStreaming"]

        do {
            let data = try JSONSerialization.data(withJSONObject: command)
            if let message = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                    print("Error sending stop streaming: \(error.localizedDescription)")
                })
            }
        } catch {
            print("Error serializing stop streaming: \(error)")
        }
    }

    /// Send BPM data to watch (for receiving side)
    func sendBPMToWatch(_ bpm: Double) {
        guard let session = session, session.isReachable else {
            return
        }

        let command: [String: Any] = [
            "type": "heartbeatData",
            "bpm": bpm,
            "timestamp": Date().timeIntervalSince1970
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: command)
            if let message = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                session.sendMessage(message, replyHandler: nil, errorHandler: nil)
            }
        } catch {
            print("Error sending BPM to watch: \(error)")
        }
    }

    // MARK: - Receiving Data from Watch
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        DispatchQueue.main.async {
            if let pairedUsersData = userInfo["pairedUsers"] as? Data {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let users = try decoder.decode([PairedUser].self, from: pairedUsersData)
                    self.pairedUsersOnWatch = users
                    print("Received \(users.count) paired users from watch")
                } catch {
                    print("Error decoding paired users from watch: \(error)")
                }
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            guard let type = message["type"] as? String else { return }

            switch type {
            case "heartbeatRequest":
                if let userId = message["userId"] as? String,
                   let userName = message["userName"] as? String {
                    print("Received heartbeat request from \(userName)")
                    self.onHeartbeatRequestReceived?(userId)
                }

            case "requestAccepted":
                print("Watch accepted heartbeat request")
                self.onHeartbeatRequestAccepted?()

            case "requestDeclined":
                print("Watch declined heartbeat request")
                self.onHeartbeatRequestDeclined?()

            case "streamingStarted":
                print("Watch started streaming heart rate")

            case "streamingStopped":
                print("Watch stopped streaming heart rate")

            case "bpmUpdate":
                if let bpm = message["bpm"] as? Double {
                    print("Received BPM from watch: \(bpm)")
                    // Forward to Firebase
                    Task {
                        await FirebaseService.shared.sendBPMToWatch(bpm)
                    }
                }

            default:
                print("Unknown message type: \(type)")
            }
        }
    }

    // MARK: - Helper Methods
    func updateApplicationContext(_ data: [String: Any]) {
        try? session?.updateApplicationContext(data)
    }
}

// MARK: - FirebaseService Extension for Watch BPM
extension FirebaseService {
    func sendBPMToWatch(_ bpm: Double) async {
        // This is called when receiving BPM from watch
        // The BPM would be forwarded to the receiving user via Firebase
        await MainActor.run {
            self.currentBPM = bpm
        }
    }
}
