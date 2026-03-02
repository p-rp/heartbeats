//
//  CodeGenerator.swift
//  heartbeats Watch App
//
//  Generates unique pairing codes
//

import Foundation

enum CodeGenerator {
    static func generatePairingCode() -> String {
        let randomNumber = String(format: "%04d", Int.random(in: 1000...9999))
        return "BEAT-\(randomNumber)"
    }
    
    static func isValidCode(_ code: String) -> Bool {
        let pattern = "^BEAT-\\d{4}$"
        return code.range(of: pattern, options: .regularExpression) != nil
    }
}
