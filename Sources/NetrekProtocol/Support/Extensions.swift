//
//  Extensions.swift
//  NetrekProtocol
//
//  Small helpers used inside the package. They are internal on purpose, so
//  they never clash with an app's own copies.
//
//  Collection(safe:) and Data.to(type:) by Darrell Root, 2019.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Data {
    init<T>(from value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.loadUnaligned(as: T.self) }
    }
}
