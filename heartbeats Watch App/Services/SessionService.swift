//
//  SessionService.swift
//  heartbeats Watch App
//
//  Manages heartbeat sessions with Realtime Database
//

import Foundation
import FirebaseDatabase

class SessionService {
    static let shared = SessionService()
    
    private let db = Database.database()
    private var sessionRef: DatabaseReference?
    private var beatsListener: DatabaseReference?
    
    private init() {}
    
    // MARK: - Request Session
    
    func requestSession(receiverId: String) async throws -> String {
        guard let senderId = FirebaseManager.shared.getCurrentUserId() else {
            throw FirebaseError.authenticationFailed
        }
        
        let sessionId = db.reference().childByAutoId().key ?? UUID().uuidString
        let sessionRef = db.reference().child("sessions").child(sessionId)
        
        let sessionData: [String: Any] = [
            "senderId": senderId,
            "receiverId": receiverId,
            "status": SessionStatus.requested.rawValue,
            "startedAt": Date().timeIntervalSince1970,
            "ttl": Date().addingTimeInterval(Constants.Session.ttlSeconds).timeIntervalSince1970
        ]
        
        try await sessionRef.setValue(sessionData)
        
        return sessionId
    }
    
    // MARK: - Accept Session
    
    func acceptSession(_ sessionId: String) async throws {
        let sessionRef = db.reference().child("sessions").child(sessionId)
        
        try await sessionRef.updateChildValues([
            "status": SessionStatus.active.rawValue
        ])
    }
    
    // MARK: - Send Heartbeat
    
    func sendHeartbeat(sessionId: String, bpm: Int) async throws {
        let beatsRef = db.reference()
            .child("sessions")
            .child(sessionId)
            .child("beats")
            .childByAutoId()
        
        let beatData: [String: Any] = [
            "bpm": bpm,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        try await beatsRef.setValue(beatData)
    }
    
    // MARK: - Listen for Beats
    
    func listenForBeats(sessionId: String, onUpdate: @escaping (Int) -> Void) {
        beatsListener = db.reference()
            .child("sessions")
            .child(sessionId)
            .child("beats")
        
        beatsListener?.observe(.childAdded) { snapshot in
            if let data = snapshot.value as? [String: Any],
               let bpm = data["bpm"] as? Int {
                DispatchQueue.main.async {
                    onUpdate(bpm)
                }
            }
        }
    }
    
    // MARK: - End Session
    
    func endSession(_ sessionId: String) async throws {
        let sessionRef = db.reference().child("sessions").child(sessionId)
        
        try await sessionRef.updateChildValues([
            "status": SessionStatus.completed.rawValue,
            "endedAt": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Listen for Session Requests
    
    func listenForSessionRequests(userId: String, onRequest: @escaping (String) -> Void) {
        db.reference()
            .child("sessions")
            .queryOrdered(byChild: "receiverId")
            .queryEqual(toValue: userId)
            .observe(.childAdded) { snapshot in
                if let data = snapshot.value as? [String: Any],
                   let status = data["status"] as? String,
                   status == SessionStatus.requested.rawValue {
                    DispatchQueue.main.async {
                        onRequest(snapshot.key)
                    }
                }
            }
    }
    
    // MARK: - Stop Listening
    
    func stopListening() {
        beatsListener?.removeAllObservers()
        beatsListener = nil
    }
}
