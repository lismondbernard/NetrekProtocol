//
//  SlotStatus.swift
//  Netrek2
//
//  Created by Darrell Root on 5/5/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import Foundation

public enum SlotStatus: Int {
    case free = 0
    case outfit = 1
    case alive = 2
    case explode = 3
    case dead = 4
    case observe = 5
}
