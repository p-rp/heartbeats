//
//  AppState.swift
//  heartbeats Watch App
//
//  Manages global app state
//

import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var isPaired: Bool = false
    @Published var partnerId: String? = nil
    @Published var partnerName: String? = nil
    
    private let userDefaults = UserDefaults.standard
    private let partnerIdKey = "pairedWith"
    private let partnerNameKey = "partnerName"
    
    init() {
        loadPairingState()
    }
    
    func loadPairingState() {
        partnerId = userDefaults.string(forKey: partnerIdKey)
        partnerName = userDefaults.string(forKey: partnerNameKey)
        isPaired = partnerId != nil
    }
    
    func savePairing(partnerId: String, partnerName: String) {
        userDefaults.set(partnerId, forKey: partnerIdKey)
        userDefaults.set(partnerName, forKey: partnerNameKey)
        self.partnerId = partnerId
        self.partnerName = partnerName
        self.isPaired = true
    }
    
    func clearPairing() {
        userDefaults.removeObject(forKey: partnerIdKey)
        userDefaults.removeObject(forKey: partnerNameKey)
        self.partnerId = nil
        self.partnerName = nil
        self.isPaired = false
    }
    
    func updatePartnerName(_ name: String) {
        userDefaults.set(name, forKey: partnerNameKey)
        self.partnerName = name
    }
}
