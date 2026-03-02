//
//  FirebaseManager.swift
//  heartbeats Watch App
//
//  Manages Firebase initialization and authentication
//

import Foundation
import FirebaseAuth

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private(set) var currentUserId: String?
    
    private init() {}
    
    func initialize() {
        // Firebase is already configured in App entry point
    }
    
    // MARK: - Anonymous Authentication
    
    func signInAnonymously() async throws -> String {
        let result = try await Auth.auth().signInAnonymously()
        let userId = result.user.uid
        currentUserId = userId
        UserDefaults.standard.set(userId, forKey: Constants.UserDefaults.userIdKey)
        return userId
    }
    
    func getCurrentUserId() -> String? {
        if let storedId = UserDefaults.standard.string(forKey: Constants.UserDefaults.userIdKey) {
            currentUserId = storedId
            return storedId
        }
        return currentUserId
    }
    
    func isAuthenticated() -> Bool {
        return getCurrentUserId() != nil
    }
}

enum FirebaseError: Error, LocalizedError {
    case authenticationFailed
    case userNotFound
    case pairingNotFound
    case sessionCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Failed to authenticate with Firebase"
        case .userNotFound:
            return "User not found"
        case .pairingNotFound:
            return "Pairing code not found"
        case .sessionCreationFailed:
            return "Failed to create session"
        }
    }
}
