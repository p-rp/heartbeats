import Foundation
import Combine
import CommonCrypto

// MARK: - Firebase Service
/// Handles all Firebase Realtime Database operations for the Heartbeats app
/// Uses URLSession for REST API calls to Firebase (no SDK dependency required)

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    // MARK: - Properties
    private var databaseURL: String = ""
    private var databaseSecret: String = ""
    private var userId: String {
        UserDefaults.standard.string(forKey: "heartbeats_user_id") ?? {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "heartbeats_user_id")
            return newId
        }()
    }

    @Published var pairedUsers: [PairedUser] = []
    @Published var currentBPM: Double = 0
    @Published var isConnected: Bool = false

    private var bpmListeners: [String: Timer] = [:]
    private var heartbeatObservers: [String: AnyCancellable] = [:]

    private init() {}

    // MARK: - Configuration
    func configure() {
        // Load Firebase configuration from UserDefaults or use defaults
        // For development, using Firebase REST API
        // Users should configure their own Firebase project

        // Check if user has set custom config
        if let customURL = UserDefaults.standard.string(forKey: "firebase_database_url") {
            self.databaseURL = customURL
        } else {
            // Default placeholder - user should replace with their Firebase project
            self.databaseURL = "https://heartbeats-app-default-rtdb.firebaseio.com"
        }

        if let customSecret = UserDefaults.standard.string(forKey: "firebase_database_secret") {
            self.databaseSecret = customSecret
        }

        loadPairedUsers()
    }

    func setCustomConfig(url: String, secret: String? = nil) {
        UserDefaults.standard.set(url, forKey: "firebase_database_url")
        if let secret = secret {
            UserDefaults.standard.set(secret, forKey: "firebase_database_secret")
        }
        self.databaseURL = url
        self.databaseSecret = secret ?? ""
    }

    // MARK: - Connection Code Generation
    /// Generates a unique 6-character connection code
    func generateConnectionCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Removed similar looking characters
        let code = String((0..<6).map { _ in characters.randomElement()! })
        return code
    }

    /// Validates a connection code and returns the associated user ID if valid
    func validateConnectionCode(_ code: String) async -> String? {
        // Query Firebase for user with this connection code
        let urlString = "\(databaseURL)/users.json?orderBy=\"connectionCode\"&equalTo=\"\(code)\""

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Find first matching user
                for (userId, userData) in json {
                    if let userDict = userData as? [String: Any],
                       userDict["connectionCode"] as? String == code {
                        return userId
                    }
                }
            }
        } catch {
            print("Error validating connection code: \(error)")
        }

        return nil
    }

    /// Registers the current user with their connection code in Firebase
    func registerUser(name: String? = nil, completion: @escaping (Bool) -> Void) {
        let code = generateConnectionCode()
        let user = FirebaseUser(id: userId, connectionCode: code, name: name)

        guard let url = URL(string: "\(databaseURL)/users/\(userId).json") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(user)

            URLSession.shared.dataTask(with: request) { _, response, error in
                DispatchQueue.main.async {
                    completion(error == nil && (response as? HTTPURLResponse)?.statusCode == 200)
                }
            }.resume()
        } catch {
            completion(false)
        }
    }

    // MARK: - Pairing Management
    /// Initiates pairing with another user via their connection code
    func pairWithUser(code: String, name: String, completion: @escaping (Bool) -> Void) {
        Task {
            if let partnerId = await validateConnectionCode(code) {
                // Create pairing in Firebase
                let pairId = [userId, partnerId].sorted().joined(separator: "_")

                guard let url = URL(string: "\(databaseURL)/pairs/\(pairId).json") else {
                    completion(false)
                    return
                }

                let pairData: [String: Any] = [
                    "user1Id": userId,
                    "user2Id": partnerId,
                    "createdAt": ISO8601DateFormatter().string(from: Date())
                ]

                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: pairData)

                    let (_, response) = try await URLSession.shared.data(for: request)

                    if (response as? HTTPURLResponse)?.statusCode == 200 {
                        // Save to local paired users
                        let pairedUser = PairedUser(id: partnerId, name: name, connectionCode: code)
                        await MainActor.run {
                            self.pairedUsers.append(pairedUser)
                            self.savePairedUsers()
                            completion(true)
                        }
                    } else {
                        completion(false)
                    }
                } catch {
                    completion(false)
                }
            } else {
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }

    /// Removes a paired user
    func removePairedUser(_ user: PairedUser) {
        pairedUsers.removeAll { $0.id == user.id }
        savePairedUsers()
    }

    // MARK: - Heart Rate Streaming
    /// Starts streaming BPM data to Firebase
    func startStreamingBPM(userId: String, bpmHandler: @escaping (Double) -> Void) {
        // Update user status
        updateUserStatus(status: .streaming)

        // Set up timer to simulate BPM updates
        // In production, this would receive real data from Watch
        bpmListeners[userId] = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // Simulated BPM - replace with actual Watch data
            let simulatedBPM = Double.random(in: 60...100)
            self?.sendBPMToFirebase(bpm: simulatedBPM, senderId: userId)
            bpmHandler(simulatedBPM)
        }
    }

    /// Sends a BPM value to Firebase
    private func sendBPMToFirebase(bpm: Double, senderId: String) {
        let dataPoint = HeartbeatDataPoint(bpm: bpm, senderId: senderId)

        guard let url = URL(string: "\(databaseURL)/users/\(senderId)/currentBPM.json") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(bpm)

            URLSession.shared.dataTask(with: request).resume()
        } catch {
            print("Error sending BPM: \(error)")
        }
    }

    /// Listens for heartbeat data from a specific user
    func listenForHeartbeat(from userId: String, handler: @escaping (Double) -> Void) {
        updateUserStatus(status: .receiving)

        let urlString = "\(databaseURL)/users/\(userId)/currentBPM.json"
        guard let url = URL(string: urlString) else { return }

        // Poll for BPM changes
        bpmListeners[userId] = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data,
                      let bpm = try? JSONDecoder().decode(Double.self, from: data) else { return }
                DispatchQueue.main.async {
                    handler(bpm)
                }
            }.resume()
        }
    }

    /// Stops all streaming and listening activities
    func stopStreaming() {
        bpmListeners.values.forEach { $0.invalidate() }
        bpmListeners.removeAll()
        updateUserStatus(status: .idle)
    }

    // MARK: - User Status
    private func updateUserStatus(status: UserStatus) {
        guard let url = URL(string: "\(databaseURL)/users/\(userId)/status.json") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(status.rawValue)
            URLSession.shared.dataTask(with: request).resume()
        } catch {
            print("Error updating status: \(error)")
        }
    }

    // MARK: - Persistence
    private func loadPairedUsers() {
        if let data = UserDefaults.standard.data(forKey: "paired_users"),
           let decoded = try? JSONDecoder().decode([PairedUser].self, from: data) {
            self.pairedUsers = decoded
        }
    }

    private func savePairedUsers() {
        if let encoded = try? JSONEncoder().encode(pairedUsers) {
            UserDefaults.standard.set(encoded, forKey: "paired_users")
        }
    }

    // MARK: - Session Management
    /// Creates a new heartbeat session
    func createSession(senderId: String, receiverId: String, duration: TimeInterval) async -> String? {
        let session = HeartbeatSession(senderId: senderId, receiverId: receiverId, duration: duration)

        guard let url = URL(string: "\(databaseURL)/sessions/\(session.id).json") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(session)

            let (_, response) = try await URLSession.shared.data(for: request)

            return (response as? HTTPURLResponse)?.statusCode == 200 ? session.id : nil
        } catch {
            print("Error creating session: \(error)")
            return nil
        }
    }

    /// Ends an active session
    func endSession(sessionId: String) {
        guard let url = URL(string: "\(databaseURL)/sessions/\(sessionId)/isActive.json") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(false)
            URLSession.shared.dataTask(with: request).resume()
        } catch {
            print("Error ending session: \(error)")
        }
    }

    /// Gets the current user's ID
    func getCurrentUserId() -> String {
        return userId
    }

    /// Gets the current user's connection code (generates if needed)
    func getOrGenerateConnectionCode() async -> String {
        // Check if user already has a connection code in Firebase
        let urlString = "\(databaseURL)/users/\(userId)/connectionCode.json"

        guard let url = URL(string: urlString) else { return generateConnectionCode() }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let existingCode = try? JSONDecoder().decode(String.self, from: data), !existingCode.isEmpty {
                return existingCode
            }
        } catch {
            // User doesn't have a code yet, generate one
        }

        // Generate and register new code
        let newCode = generateConnectionCode()
        await registerUserWithCode(newCode)
        return newCode
    }

    private func registerUserWithCode(_ code: String) async {
        let user = FirebaseUser(id: userId, connectionCode: code, name: nil)

        guard let url = URL(string: "\(databaseURL)/users/\(userId).json") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(user)

            let (_, response) = try await URLSession.shared.data(for: request)
            print("Registration result: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        } catch {
            print("Error registering user: \(error)")
        }
    }
}
