//
//  User.swift
//  heartbeats Watch App
//
//  User model for Firebase
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    var pairCode: String?
    var pairedWith: String?
    var pairedWithName: String?
    var createdAt: Date
    
    init(id: String, pairCode: String? = nil, pairedWith: String? = nil) {
        self.id = id
        self.pairCode = pairCode
        self.pairedWith = pairedWith
        self.pairedWithName = nil
        self.createdAt = Date()
    }
}
