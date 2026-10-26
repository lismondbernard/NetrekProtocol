//
//  MetaServer.swift
//  Netrek
//
//  Created by Darrell Root on 3/1/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Combine)
import Combine
#endif

/// The list of Netrek servers: a few well-known ones, the servers the
/// metaserver (metaserver.netrek.org, port 3521) reports, and servers found
/// on the local network over Bonjour (`_netrek._tcp`).
public class MetaServer: ObservableObject {
    public var onMetaserverUpdated: (() -> Void)?
    public let metahosts: [String]  //primary server hostname
    public let port: Int
    //let url: URL
    var dataTasks: [String:URLSessionDataTask] = [:] // hostname:URLSessionDataTask
    let defaultSession = URLSession(configuration: .default)
    let newlineCharacters = NSCharacterSet.newlines
    let whiteSpace = NSCharacterSet.whitespaces
    
    @Published public var servers: [String:MetaServerEntry] = [:]  // hostname:MetaServerEntry
    #if canImport(Network)
    var localServerBrowser: LocalServerBrowser?
    #endif

    public init?(primary: String, backup: String, port: Int) {
        self.metahosts = [primary,backup]
        self.port = port
        //let primaryUrlString = "http://\(primary):\(port)"
        //guard let urlComponents = URLComponents(string: urlString ) else { return nil }
        //guard let url = urlComponents.url else { return nil }
        //self.url = url
        let pickled = MetaServerEntry(hostname: "pickled.netrek.org", port: 2592, age: 1000, players: 0, type: .bronco)
        let continuum = MetaServerEntry(hostname: "continuum.us.netrek.org", port: 2592, age: 1000, players: 0, type: .bronco)
        let networkmom = MetaServerEntry(hostname: "netrek.networkmom.net", port: 2592, age: 1000, players: 0, type: .empire)
        self.servers[networkmom.hostname] = networkmom
        self.servers[pickled.hostname] = pickled
        self.servers[continuum.hostname] = continuum

        #if canImport(Network)
        self.localServerBrowser = LocalServerBrowser(metaServer: self)
        self.localServerBrowser?.start()
        #endif
    }

    public func update() {
        for host in metahosts {
            update(metahost: host)
        }
    }

    public func refreshLocalDiscovery() {
        #if canImport(Network)
        localServerBrowser?.stop()
        localServerBrowser = LocalServerBrowser(metaServer: self)
        localServerBrowser?.start()
        #endif
    }
    public func update(metahost: String) {
        let urlString = "http://\(metahost):\(self.port)"
        guard let urlComponents = URLComponents(string: urlString ) else {
            debugPrint("Failed to get url components from \(urlString) in MetaServer.swift")
            return
        }
        guard let url = urlComponents.url else {
            debugPrint("MetaServer.swift: error computing url components")
            return
        }

        if let dataTask = dataTasks[metahost] {
            dataTask.cancel()
        }
        let dataTask = defaultSession.dataTask(with: url) { data, response, error in
            defer {
                self.dataTasks[metahost] = nil
            }
            if let error = error {
                debugPrint("MetaServer.update dataTask error when contacting metaserver url \(url) error \(error.localizedDescription)")
            } else if let data = data {
                //debugPrint("MetaServer data \(data)")
                if let dataString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        // Preserve local server entries discovered via Bonjour
                        let localEntries = self.servers.filter { $0.value.isLocal }
                        self.servers = localEntries
                        let lines = dataString.components(separatedBy: self.newlineCharacters)
                        for line in lines {
                            //debugPrint("\(line) length \(line.count)")
                            if line.count == 79 {  // this length line has a metaserver entry
                                //let components = line.components(separatedBy: self.whiteSpace)
                                let allComponents = line.components(separatedBy: " ")
                                let components = allComponents.filter { $0 != ""}
                                //debugPrint("components \(components.count)")
                                if components.count > 6 {
                                    let hostname = components[1]
                                    let portString = components[3]
                                    let ageString = components[4]
                                    //let status = components[5]
                                    let possiblePlayers = components[6]
                                    let port = Int(portString)
                                    let age = Int(ageString)
                                    
                                    let players = Int(possiblePlayers) ?? 0
                                    let possibleType = components.last
                                    if let port = port, let age = age, let possibleType = possibleType {
                                        for type in MetaServerType.allCases {
                                            if possibleType == type.rawValue {
                                                let server = MetaServerEntry(hostname: hostname, port: port, age: age, players: players, type: type)
                                                self.servers[server.hostname] = server
                                                debugPrint("MetaServer.update: found server \(server.description)")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.onMetaserverUpdated?()
                    }
                }
            }
        }
        dataTasks[metahost] = dataTask
        dataTask.resume()
    }
}
