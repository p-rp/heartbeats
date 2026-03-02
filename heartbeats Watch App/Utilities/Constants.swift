//
//  Constants.swift
//  heartbeats Watch App
//
//  App-wide constants
//

import Foundation

enum Constants {
    enum Firebase {
        static let usersCollection = "users"
        static let pairingsCollection = "pairings"
        static let sessionsCollection = "sessions"
    }
    
    enum UserDefaults {
        static let userIdKey = "userId"
        static let pairedWithKey = "pairedWith"
        static let partnerNameKey = "partnerName"
    }
    
    enum Session {
        static let durationSeconds: TimeInterval = 10
        static let ttlSeconds: TimeInterval = 60
        static let bpmUpdateIntervalMs: Double = 500
    }
    
    enum UI {
        static let animationDuration: Double = 0.3
        static let cornerRadius: CGFloat = 12
    }
}
