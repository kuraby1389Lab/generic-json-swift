//
//  JSONPatch+Operation.swift
//  GenericJSON
//
//  Created by Trystan Pfluger on 12/1/2023.
//

import Foundation

public struct JSONPatchOperation: Equatable, Codable {
    
    public enum Code: String, Codable {
        case add
        case remove
        case replace
        case copy
        case move
        case test
        case unknown
    }

    public enum CodingKeys: String, CodingKey {
        case code = "op"
        case path
        case value
        case from
    }
    
    public init(_ code: Code, path: JSONPatchOperationPathCapable? = nil, from: JSONPatchOperationPathCapable? = nil, value: JSON? = nil) {
        self.code = code
        self.path = path?.getOperationPath()
        self.from = from?.getOperationPath()
        self.value = value
    }
    
    public var code: Code
    public var path: String?
    public var from: String?
    public var value: JSON?
    
}

extension JSONPatchOperation: CustomStringConvertible {
    public var description: String {
        var fields:[String] = []
        if let path = path { fields.append("path: \(path)") }
        if let from = from { fields.append("from: \(from)") }
        if let value = value { fields.append("value: \(value.contentType.rawValue)") }
        return "Operation(\(code.rawValue), \(fields.joined(separator: ", ")))"
    }
}

public typealias JSONPatch = [JSONPatchOperation]

extension JSONPatch {
    public typealias Operation = Element
}


public protocol JSONPatchOperationPathCapable {
    func getOperationPath() -> String
}

extension String: JSONPatchOperationPathCapable {
    public func getOperationPath() -> String { self }
}

extension Array: JSONPatchOperationPathCapable where Element == JSONPatch.Token {
    public func getOperationPath() -> String { JSONPatch.encodePointer(self) }
}

public extension JSONPatchOperation {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let code = try container.decode(JSONPatch.Operation.Code.self, forKey: .code)
        let path = try container.decodeIfPresent(String.self, forKey: .path)
        let from = try container.decodeIfPresent(String.self, forKey: .from)

        let value:JSON?
        if container.contains(.value) {
            value = try container.decode(JSON.self, forKey: .value)
        } else {
            value = nil
        }
        
        self.init(code, path: path, from: from, value: value)
    }
}

public extension JSONPatchOperation {
    
    static func add(path: JSONPatchOperationPathCapable, value: JSON) -> JSONPatchOperation {
        return .init(.add, path: path, value: value)
    }
    
    static func remove(path: JSONPatchOperationPathCapable) -> JSONPatchOperation {
        return .init(.remove, path: path)
    }
    
    static func replace(path: JSONPatchOperationPathCapable, value: JSON) -> JSONPatchOperation {
        return .init(.replace, path: path, value: value)
    }
    
    static func copy(path: JSONPatchOperationPathCapable, from: JSONPatchOperationPathCapable) -> JSONPatchOperation {
        return .init(.copy, path: path, from: from)
    }
    
    static func move(path: JSONPatchOperationPathCapable, from: JSONPatchOperationPathCapable) -> JSONPatchOperation {
        return .init(.move, path: path, from: from)
    }
    
    static func test(path: JSONPatchOperationPathCapable, value: JSON) -> JSONPatchOperation {
        return .init(.test, path: path, value: value)
    }
    
}

public extension JSONPatchOperation {
    
}


extension JSONPatchOperation.Code {
    public init(from decoder: Decoder) throws {
        self = try JSONPatch.Operation.Code(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

public extension JSONPatchOperation {
    
    var pathPointer: JSONPatch.Pointer? {
        get throws {
            guard let path = path else { return nil }
            return try JSONPatch.decodePointer(from: path)
        }
    }
    
    var fromPointer: JSONPatch.Pointer? {
        get throws {
            guard let from = from else { return nil }
            return try JSONPatch.decodePointer(from: from)
        }
    }
    
    var isLegal:Bool {
        guard path != nil else { return false }
        switch code {
        case .add, .replace, .test:
            return (from == nil && value != nil)
        case .remove:
            return (from == nil && value == nil)
        case .copy, .move:
            return (from != nil && value == nil)
        case .unknown:
            return false
        }
    }
}
