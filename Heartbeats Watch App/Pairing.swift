//
//  Pairing.swift
//  heartbeats Watch App
//
//  Pairing relationship model
//

import Foundation

struct Pairing: Codable, Identifiable {
    let id: String  // This is the pairCode (e.g., "BEAT-1234")
    var userA: String  // User ID
    var userB: String  // User ID
    var userAName: String?
    var userBName: String?
    var createdAt: Date
    
    init(id: String, userA: String, userB: String) {
        self.id = id
        self.userA = userA
        self.userB = userB
        self.userAName = nil
        self.userBName = nil
        self.createdAt = Date()
    }
}
