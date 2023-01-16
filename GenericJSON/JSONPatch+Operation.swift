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
    
    public init(_ code: Code, path: String? = nil, from: String? = nil, value: JSON? = nil) {
        self.code = code
        self.path = path
        self.from = from
        self.value = value
    }
    
    public var code: Code
    public var path: String?
    public var from: String?
    public var value: JSON?
    
}

public typealias JSONPatch = [JSONPatchOperation]

extension JSONPatch {
    public typealias Operation = Element
}

extension JSONPatchOperation {
    public init(from decoder: Decoder) throws {
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


extension JSONPatchOperation.Code {
    public init(from decoder: Decoder) throws {
        self = try JSONPatch.Operation.Code(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

extension JSONPatchOperation {
    /// Create an Operation value from an `Encodable`
//    public init<T: Encodable>(encodable: T) throws {
//        let encoded = try JSONEncoder().encode(encodable)
//        self = try JSONDecoder().decode(JSONPatch.Operation.self, from: encoded)
//    }
    
}

extension JSONPatchOperation {
    
    public var pathPointer: JSONPatch.Pointer? {
        get throws {
            guard let path = path else { return nil }
            return try JSONPatch.decodePointer(from: path)
        }
    }
    
    public var fromPointer: JSONPatch.Pointer? {
        get throws {
            guard let from = from else { return nil }
            return try JSONPatch.decodePointer(from: from)
        }
    }
    
    public var isLegal:Bool {
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
