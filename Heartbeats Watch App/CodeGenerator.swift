//
//  CodeGenerator.swift
//  heartbeats Watch App
//
//  Generates unique pairing codes
//

import Foundation

enum CodeGenerator {
    static func generatePairingCode() -> String {
        return String(format: "%06d", Int.random(in: 0...999999))
    }
    
    static func isValidCode(_ code: String) -> Bool {
        let pattern = "^\\d{6}$"
        return code.range(of: pattern, options: .regularExpression) != nil
    }
}
