//
//  HeartbeatData.swift
//  heartbeats Watch App
//
//  Single heartbeat data point
//

import Foundation

struct HeartbeatData: Codable {
    let bpm: Int
    let timestamp: TimeInterval  // Unix timestamp
    
    init(bpm: Int) {
        self.bpm = bpm
        self.timestamp = Date().timeIntervalSince1970
    }
}
