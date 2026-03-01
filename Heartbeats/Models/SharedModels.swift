import Foundation

// MARK: - Shared Data Models

/// User status in the heartbeat sharing session
enum UserStatus: String, Codable {
    case idle
    case streaming
    case receiving
}

/// Represents a paired user that can be connected to
struct PairedUser: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    let connectionCode: String
    var pairedAt: Date

    init(id: String = UUID().uuidString, name: String, connectionCode: String) {
        self.id = id
        self.name = name
        self.connectionCode = connectionCode
        self.pairedAt = Date()
    }
}

/// Represents an active heartbeat session
struct HeartbeatSession: Codable, Identifiable {
    let id: String
    let senderId: String
    let receiverId: String
    let startTime: Date
    var duration: TimeInterval
    var isActive: Bool

    init(id: String = UUID().uuidString, senderId: String, receiverId: String, duration: TimeInterval = 60) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.startTime = Date()
        self.duration = duration
        self.isActive = true
    }
}

/// Represents a heartbeat data point with timestamp
struct HeartbeatDataPoint: Codable {
    let bpm: Double
    let timestamp: Date
    let senderId: String

    init(bpm: Double, senderId: String) {
        self.bpm = bpm
        self.timestamp = Date()
        self.senderId = senderId
    }
}

/// Firebase database user representation
struct FirebaseUser: Codable {
    let id: String
    var connectionCode: String
    var currentBPM: Double?
    var status: UserStatus
    var name: String?

    init(id: String, connectionCode: String, name: String? = nil) {
        self.id = id
        self.connectionCode = connectionCode
        self.currentBPM = nil
        self.status = .idle
        self.name = name
    }
}
