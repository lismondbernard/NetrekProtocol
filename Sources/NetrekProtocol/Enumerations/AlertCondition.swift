//
//  AlertCondition.swift
//  Netrek2
//
//  Created by Darrell Root on 5/5/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import Foundation

/// The ship's alert level, from the green/yellow/red flags in SP_YOU.
public enum AlertCondition: CaseIterable {
    case green
    case yellow
    case red
}
