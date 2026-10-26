//
//  LocalServerBrowser.swift
//  Netrek
//
//  Finds Netrek servers on the local network over Bonjour (_netrek._tcp)
//  and adds them to a MetaServer's list.
//

import Foundation
#if canImport(Network)
import Network
#if canImport(Combine)
import Combine
#endif

public class LocalServerBrowser: ObservableObject {
    private var browser: NWBrowser?
    private weak var metaServer: MetaServer?
    private var localHostnames: Set<String> = []
    private var pendingConnections: [NWConnection] = []

    public init(metaServer: MetaServer) {
        self.metaServer = metaServer
    }

    public func start() {
        let params = NWParameters()
        params.includePeerToPeer = true
        browser = NWBrowser(for: .bonjour(type: "_netrek._tcp", domain: nil), using: params)

        browser?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                debugPrint("LocalServerBrowser: browsing for _netrek._tcp")
            case .failed(let error):
                debugPrint("LocalServerBrowser: failed \(error)")
            default:
                break
            }
        }

        browser?.browseResultsChangedHandler = { results, changes in
            for change in changes {
                switch change {
                case .added(let result):
                    self.resolve(result: result)
                case .removed(let result):
                    self.remove(result: result)
                default:
                    break
                }
            }
        }

        browser?.start(queue: .main)
    }

    public func stop() {
        browser?.cancel()
        browser = nil
        for conn in pendingConnections {
            conn.cancel()
        }
        pendingConnections.removeAll()
        for hostname in localHostnames {
            metaServer?.servers.removeValue(forKey: hostname)
        }
        localHostnames.removeAll()
    }

    private func resolve(result: NWBrowser.Result) {
        let serviceName: String
        if case .service(let name, _, _, _) = result.endpoint {
            serviceName = name
        } else {
            return
        }

        // Create a connection to resolve the service endpoint to a host:port
        let connection = NWConnection(to: result.endpoint, using: .tcp)
        pendingConnections.append(connection)

        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .preparing:
                // The path is available once preparing begins
                if let innerEndpoint = connection.currentPath?.remoteEndpoint,
                   case .hostPort(let host, let port) = innerEndpoint {
                    self.addEntry(host: host, port: port, serviceName: serviceName)
                    connection.cancel()
                    self.removePendingConnection(connection)
                }
            case .ready:
                if let innerEndpoint = connection.currentPath?.remoteEndpoint,
                   case .hostPort(let host, let port) = innerEndpoint {
                    self.addEntry(host: host, port: port, serviceName: serviceName)
                }
                connection.cancel()
                self.removePendingConnection(connection)
            case .failed, .cancelled:
                self.removePendingConnection(connection)
            default:
                break
            }
        }
        connection.start(queue: .main)

        // Timeout: clean up if resolution takes too long
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            if self.pendingConnections.contains(where: { $0 === connection }) {
                connection.cancel()
                self.removePendingConnection(connection)
            }
        }
    }

    private func addEntry(host: NWEndpoint.Host, port: NWEndpoint.Port, serviceName: String) {
        let hostname: String
        switch host {
        case .ipv4(let addr):
            hostname = "\(addr)"
        case .ipv6(let addr):
            hostname = "\(addr)"
        case .name(let name, _):
            hostname = name
        @unknown default:
            hostname = "\(host)"
        }
        let portInt = Int(port.rawValue)

        guard !localHostnames.contains(hostname) else { return }

        let entry = MetaServerEntry(hostname: hostname, port: portInt, age: 0, players: 0, type: .other)
        entry.isLocal = true
        entry.localName = serviceName
        metaServer?.servers[hostname] = entry
        localHostnames.insert(hostname)
        debugPrint("LocalServerBrowser: discovered \(serviceName) at \(hostname):\(portInt)")
    }

    private func removePendingConnection(_ connection: NWConnection) {
        pendingConnections.removeAll { $0 === connection }
    }

    private func remove(result: NWBrowser.Result) {
        if case .service(let name, _, _, _) = result.endpoint {
            for hostname in localHostnames {
                if let entry = metaServer?.servers[hostname], entry.localName == name {
                    metaServer?.servers.removeValue(forKey: hostname)
                    localHostnames.remove(hostname)
                    debugPrint("LocalServerBrowser: removed \(name)")
                    break
                }
            }
        }
    }

    deinit {
        browser?.cancel()
        for conn in pendingConnections {
            conn.cancel()
        }
    }
}
#endif
