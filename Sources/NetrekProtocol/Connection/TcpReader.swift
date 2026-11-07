//
//  TcpReader.swift
//  Netrek
//
//  Created by Darrell Root on 3/1/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
#if canImport(Network)
import Network

/// A TCP connection to a Netrek game server (port 2592 by default), built on
/// Network.framework. Bytes read are handed to `delegate.gotData`; call
/// `receive()` again once they are processed (`PacketAnalyzer` asks for this
/// through `PacketAnalyzerDelegate.triggerReceive()`).
public class TcpReader {
    //var timer: Timer?
    public let hostname: String
    public let port: Int
    public let connection: NWConnection
    public var delegate: NetworkDelegate
    let queue: DispatchQueue
    var receiving: Bool = false // primitive lock on receiving
    var receiveCount: Int = 0
    var complete = false // set to true once we get complete in our receive closure
    /// Set once the end of the connection has been reported, so it is
    /// reported once. Callbacks run on a concurrent queue, hence the lock.
    private var endReported = false
    /// Set by `resetConnection()`.
    private var closedByClient = false
    private let endLock = NSLock()
    public init?(hostname: String, port: Int, delegate: NetworkDelegate) {
        self.hostname = hostname
        self.port = port
        self.delegate = delegate
        let serverEndpoint = NWEndpoint.Host(hostname)
        guard hostname.count > 2 else {
            return nil
        }
        guard port <= UInt16.max else { return nil }
        guard port > 0 else { return nil }
        let port = UInt16(port)
        queue = DispatchQueue(label: "hostname", attributes: .concurrent)
        guard let portEndpoint = NWEndpoint.Port(rawValue: port) else { return nil }
        //var options = NWProtocolTCP.Options()
        //options.noDelay = true

        //var parameters = NWParameters()
        //parameters.
        //let ipOptions = NWParameters().defaultProtocolStack.transportProtocol as? NWProtocolTCP.Options
        //ipOptions?.noDelay = true

        connection = NWConnection(host: serverEndpoint, port: portEndpoint, using: .tcp)
        //let connection2 = NWConnection(host: serverEndpoint, port: portEndpoint, using: ipOptions!)
        connection.stateUpdateHandler = { [weak self] (newState) in
            switch newState {
            case .ready:
                debugPrint("TcpReader.ready to send")
                if let extDelegate = self?.delegate as? NetworkDelegateExtended {
                    extDelegate.connectionStateChanged(connected: true)
                }
                self?.receive()
            case .failed(let error):
                debugPrint("TcpReader.client failed with error \(error)")
                guard self?.markEndReported() == true else { return }
                if let extDelegate = self?.delegate as? NetworkDelegateExtended {
                    extDelegate.connectionStateChanged(connected: false)
                }
            case .setup:
                debugPrint("TcpReader.setup")
            case .waiting(_):
                debugPrint("TcpReader.waiting")
            case .preparing:
                debugPrint("TcpReader.preparing")
            case .cancelled:
                debugPrint("TcpReader.cancelled")
                guard self?.markEndReported() == true else { return }
                if let extDelegate = self?.delegate as? NetworkDelegateExtended {
                    extDelegate.connectionStateChanged(connected: false)
                }
            }
        }
        
        connection.start(queue: queue)
    }
    public func resetConnection() {
        // The receive waiting now finishes with an error. That end is ours,
        // not news, so it is not reported as connectionEnded; `.cancelled`
        // still reports the disconnect, as it always has.
        endLock.lock()
        closedByClient = true
        endLock.unlock()
        self.connection.cancel()
    }
    public func receive() {
        guard self.complete == false else {
            debugPrint("TCPReader.receive: already complete.  not trying to receive")
            return
        }
        guard self.connection.state == .ready else {
            debugPrint("TCPReader.receive: connection state \(self.connection.state) no trying to receive")
            return
        }
        //debugPrint("TCPReader.receive: initiating receive count \(receiveCount)")
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16384) { (content, context, isComplete, error) in
            //debugPrint("In receive closure count \(self.receiveCount)")
            if (content?.count ?? 0) > 0 {
                debugPrint("\(Date()) TcpReader: got a message \(String(describing: content?.count)) bytes")
            }
            let step = ReceiveStep.after(byteCount: content?.count ?? 0, isComplete: isComplete,
                                         errorDescription: error.map { "\($0)" })
            if let content = content, !content.isEmpty {
                //debugPrint("content startIndex \(content.startIndex) endIndex \(content.endIndex)" )
                self.delegate.gotData(data: content, from: self.hostname, port: self.port)
            }
            // After bytes, PacketAnalyzer asks for more (triggerReceive).
            // Every other outcome is handled here, so reading never just stops.
            switch step {
            case .handedOn:
                break
            case .receiveAgain:
                self.receive()
            case .end(let end):
                self.end(end)
            }
        }
        //debugPrint("leaving receive count \(self.receiveCount)")
        receiveCount = receiveCount + 1
        //debugPrint("returning from trying to receive data")
    }
    
    /// True the first time only: whoever gets true reports the end.
    private func markEndReported() -> Bool {
        endLock.lock()
        defer { endLock.unlock() }
        if endReported { return false }
        endReported = true
        return true
    }

    /// Reading is over: say why, once, and close our side.
    private func end(_ end: ConnectionEnd) {
        complete = true
        endLock.lock()
        let ours = closedByClient
        endLock.unlock()
        guard !ours else {
            debugPrint("TcpReader.end after resetConnection: \(end)")
            return
        }
        debugPrint("TcpReader.end: \(end)")
        if markEndReported() {
            if let extDelegate = delegate as? NetworkDelegateExtended {
                extDelegate.connectionEnded(end)
            }
        }
        connection.cancel()
    }

    public func send(content: Data) {
        debugPrint("\(Date()) TcpReader.sending data \(content.count) bytes")
        connection.send(content: content, completion: .contentProcessed({ (error) in
            if let error = error {
                print("send error: \(error)")
            }
        }))
    }
}

extension TcpReader: NetworkSending {}
#endif
