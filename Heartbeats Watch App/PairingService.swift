//
//  PairingService.swift
//  heartbeats Watch App
//
//  Handles pairing operations with Realtime Database
//

import Foundation
import FirebaseDatabase

class PairingService {
    static let shared = PairingService()
    
    private let db = Database.database()
    
    private init() {}
    
    // MARK: - Create Pairing Code
    
    func createPairingCode(for userId: String) async throws -> String {
        let code = CodeGenerator.generatePairingCode()
        
        let userRef = db.reference().child("users").child(userId)
        
        try await userRef.setValue([
            "id": userId,
            "pairCode": code,
            "createdAt": Date().timeIntervalSince1970
        ])
        
        return code
    }
    
    // MARK: - Find Pairing Code
    
    func findPairing(byCode code: String) async throws -> (userId: String, pairCode: String)? {
        let snapshot = try await db.reference()
            .child("users")
            .queryOrdered(byChild: "pairCode")
            .queryEqual(toValue: code)
            .getData()
        
        guard let value = snapshot.value as? [String: Any] else {
            return nil
        }
        
        for (userId, data) in value {
            if let userData = data as? [String: Any],
               let storedCode = userData["pairCode"] as? String {
                return (userId, storedCode)
            }
        }
        
        return nil
    }
    
    // MARK: - Complete Pairing
    
    func completePairing(userA: String, userB: String) async throws {
        try await db.reference().updateChildValues([
            "users/\(userA)/pairedWith": userB,
            "users/\(userA)/pairedWithName": "Partner",
            "users/\(userB)/pairedWith": userA,
            "users/\(userB)/pairedWithName": "Partner"
        ])
        
        UserDefaults.standard.set(userB, forKey: Constants.UserDefaults.pairedWithKey)
        UserDefaults.standard.set("Partner", forKey: Constants.UserDefaults.partnerNameKey)
    }
    
    // MARK: - Get User
    
    func getUser(userId: String) async throws -> User? {
        let snapshot = try await db.reference()
            .child("users")
            .child(userId)
            .getData()
        
        guard let value = snapshot.value as? [String: Any] else {
            return nil
        }
        
        return User(
            id: userId,
            pairCode: value["pairCode"] as? String,
            pairedWith: value["pairedWith"] as? String
        )
    }
    
    // MARK: - Check if Paired
    
    func checkIfPaired(userId: String) async -> Bool {
        do {
            let user = try await getUser(userId: userId)
            return user?.pairedWith != nil
        } catch {
            return false
        }
    }
}
