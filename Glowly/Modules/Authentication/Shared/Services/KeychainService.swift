//
//  KeychainService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//

import Foundation
import Security

// MARK: - KeychainService Protocol for DI
protocol KeychainServiceProtocol {
    func save(_ data: Data, forKey key: String) -> Bool
    func save(_ string: String, forKey key: String) -> Bool
    func retrieve(forKey key: String) -> Data?
    func retrieveString(forKey key: String) -> String?
    func delete(forKey key: String) -> Bool
    func update(_ data: Data, forKey key: String) -> Bool
    func clearAll() -> Bool
}

final class KeychainService: KeychainServiceProtocol {
    // Removed singleton - use dependency injection instead
    init() {}
    
    // MARK: - Save
    
    func save(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func save(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, forKey: key)
    }
    
    // MARK: - Retrieve
    
    func retrieve(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    func retrieveString(forKey key: String) -> String? {
        guard let data = retrieve(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Delete
    
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Update
    
    func update(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if status == errSecItemNotFound {
            // Item doesn't exist, save it
            return save(data, forKey: key)
        }
        
        return status == errSecSuccess
    }
    
    // MARK: - Clear All
    
    func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Keychain Keys

extension KeychainService {
    enum Keys {
        static let userToken = "com.glowly.userToken"
        static let userEmail = "com.glowly.userEmail"
        static let userId = "com.glowly.userId"
        static let refreshToken = "com.glowly.refreshToken"
        static let biometricEnabled = "com.glowly.biometricEnabled"
    }
}

