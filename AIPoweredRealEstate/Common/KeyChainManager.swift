//
//  KeyChainManager.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import Foundation
import Security
/*
 KeychainManager is a wrapper around Apple's Security framework that provides a centralized and reusable way to securely store, retrieve, update, and delete sensitive data such as authentication tokens.
 */

class KeyChainManager {

    static let shared = KeyChainManager()
    private let service = "com.aipoweredrealestate.auth"
    private let defaultsTokenKey = "token"

    func saveValue(value: String, key: String) {
       
        let normalized = Self.normalizedAuthToken(value)
        
        if key == "token" {
            UserDefaults.standard.set(normalized, forKey: defaultsTokenKey)
        }

        guard let data = normalized.data(using: .utf8) else { return }
        let query = baseQuery(key: key, service: service)
        SecItemDelete(query as CFDictionary)

        var add = query
       
        add[kSecValueData as String] = data
       
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
       
        let addStatus = SecItemAdd(add as CFDictionary, nil)
       
        if addStatus == errSecDuplicateItem {
            SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        }
        
    }

    func getValue(key: String) -> String? {
        if key == "token" {
            let stored = Self.normalizedAuthToken(UserDefaults.standard.string(forKey: defaultsTokenKey))
            if stored.isEmpty == false { return stored }
        }

        if let value = readValue(key: key, service: service) {
            let normalized = Self.normalizedAuthToken(value)
            if key == "token", normalized.isEmpty == false {
                UserDefaults.standard.set(normalized, forKey: defaultsTokenKey)
            }
            return normalized
        }
        if let value = readValue(key: key, service: nil) {
            let normalized = Self.normalizedAuthToken(value)
            if normalized.isEmpty == false {
                saveValue(value: normalized, key: key)
            }
            return normalized
        }
        return nil
    }

    @discardableResult
    func deleteValue(key: String) -> Bool {
        if key == "token" {
            UserDefaults.standard.removeObject(forKey: defaultsTokenKey)
        }
        let withService = SecItemDelete(baseQuery(key: key, service: service) as CFDictionary)
        let withoutService = SecItemDelete(baseQuery(key: key, service: nil) as CFDictionary)
        return withService == errSecSuccess || withoutService == errSecSuccess
    }

    static func normalizedAuthToken(_ raw: String?) -> String {
        var token = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if token.count >= 2, token.hasPrefix("\""), token.hasSuffix("\"") {
            token = String(token.dropFirst().dropLast())
        }
        token = token.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        if token.lowercased().hasPrefix("bearer") {
            token = String(token.dropFirst(6))
        }
        return token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func readValue(key: String, service: String?) -> String? {
        var query = baseQuery(key: key, service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func baseQuery(key: String, service: String?) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        if let service {
            query[kSecAttrService as String] = service
        }
        return query
    }
}
