//
//  NetworkConfiguration.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 09/10/25.
//

import Foundation

struct NetworkConfiguration {
    let baseURL: String
    let defaultHeaders: [String: String]
    let timeoutInterval: TimeInterval
    let enableLogging: Bool
    
    init(
        baseURL: String,
        defaultHeaders: [String: String] = [:],
        timeoutInterval: TimeInterval = 30,
        enableLogging: Bool = true
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeoutInterval = timeoutInterval
        self.enableLogging = enableLogging
    }
    
    // MARK: - Predefined Configurations
    
    /// Development configuration.
    /// For local testing on device: change baseURL to your Mac's local WiFi IP, e.g. "http://192.168.1.X:8080"
    /// Run `ifconfig | grep "inet " | grep -v 127` on Mac to find the IP.
    static let development = NetworkConfiguration(
        baseURL: "http://192.168.0.102:8080",
        defaultHeaders: [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ],
        enableLogging: true
    )
    
    /// Staging configuration
    static let staging = NetworkConfiguration(
        baseURL: "https://api-staging.glowly.app",
        defaultHeaders: [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ],
        enableLogging: true
    )
    
    /// Production configuration
    static let production = NetworkConfiguration(
        baseURL: "https://api.glowly.app",
        defaultHeaders: [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ],
        enableLogging: false
    )
    
    /// Mock configuration for testing
    static let mock = NetworkConfiguration(
        baseURL: "https://mock.glowly.app",
        defaultHeaders: [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ],
        enableLogging: true
    )
}

