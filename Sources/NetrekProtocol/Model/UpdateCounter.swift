//
//  TimerCount.swift
//  Netrek2
//
//  Created by Darrell Root on 7/24/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

/// A counter views can watch; `Universe.serverUpdate` goes up once per
/// batch of packets analyzed.
public class UpdateCounter: ObservableObject {
    @Published public private(set) var count: Int = 0
    public let name: String
    public init(name: String) {
        self.name = name
    }
    public func increment() {
        DispatchQueue.main.async {
            self.count += 1
            //debugPrint("counter \(self.name) \(self.count)")
        }
    }
}
