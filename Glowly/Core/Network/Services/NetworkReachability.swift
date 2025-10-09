//
//  NetworkReachability.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 09/10/25.
//

import Foundation
import Network

// MARK: - NetworkReachability Protocol for DI (Rule #2)
protocol NetworkReachabilityProtocol {
    var isConnected: Bool { get }
    func startMonitoring()
    func stopMonitoring()
    func setConnectionChangeHandler(_ handler: @escaping (Bool) -> Void)
}

// MARK: - NetworkReachability Implementation
final class NetworkReachability: NetworkReachabilityProtocol {
    // MARK: - Properties
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var connectionChangeHandler: ((Bool) -> Void)?
    
    private(set) var isConnected: Bool = true {
        didSet {
            if oldValue != isConnected {
                connectionChangeHandler?(isConnected)
            }
        }
    }
    
    // MARK: - Initialization with Dependency Injection (Rule #2)
    init(queue: DispatchQueue = DispatchQueue(label: "com.glowly.network.reachability")) {
        self.monitor = NWPathMonitor()
        self.queue = queue
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Starts monitoring network connectivity
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }
    
    /// Stops monitoring network connectivity
    func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Sets a handler to be called when connection status changes
    /// - Parameter handler: Closure called with connection status (true = connected, false = disconnected)
    func setConnectionChangeHandler(_ handler: @escaping (Bool) -> Void) {
        self.connectionChangeHandler = handler
    }
}

