//
//  Observation.swift
//  NetrekProtocol
//
//  The model classes are ObservableObjects with @Published properties, so a
//  SwiftUI client can watch them directly. Combine only exists on Apple
//  platforms; elsewhere (Linux) these stand-ins keep the same source
//  compiling, without change notifications. Files that use them import
//  Combine under `#if canImport(Combine)`.
//

#if !canImport(Combine)
public protocol ObservableObject: AnyObject {}

@propertyWrapper
public struct Published<Value> {
    public var wrappedValue: Value
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
#endif
