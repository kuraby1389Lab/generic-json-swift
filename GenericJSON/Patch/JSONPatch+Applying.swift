//
//  JSONPatch+Applying.swift
//  GenericJSON
//
//  Created by Trystan Pfluger on 11/1/2023.
//

import Foundation

extension JSONPatch {
    
    private static func getTokenIndex(for token:Token) -> Int? {
        guard let tokenIndex = Int(token) else { return nil }
        guard "\(tokenIndex)" == token else { return nil }
        return tokenIndex
    }
    
    static func remove(at path: Pointer, in object: JSON.Object) throws -> JSON.Object {
        let token = path[0]
        var object = object
        if path.count == 1 {
            if object[token] != nil {
                object[token] = nil
            } else {
                throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
            }

        } else {
            let childPath = Pointer(path.dropFirst())
            if let child = object[token] {
                object[token] = try remove(at: childPath, in: child)
            } else {
                throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
            }
        }
        return object
    }

    static func remove(at path: Pointer, in array: JSON.Array) throws -> JSON.Array {
        let token = path[0]
        var array = array
        if path.count == 1 {
            if let tokenIndex = getTokenIndex(for: token), tokenIndex >= 0, tokenIndex < array.count {
                array.remove(at: tokenIndex)
            } else if token == "-" {
                array.removeLast()
            } else {
                throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
            }

        } else {
            let childPath = Pointer(path.dropFirst())
            if let tokenIndex = getTokenIndex(for: token), tokenIndex >= 0, tokenIndex < array.count {
                array[tokenIndex] = try remove(at: childPath, in: array[tokenIndex])
            } else if token == "-", let last = array.last {
                array.append(try remove(at: childPath, in: last))
            } else {
                throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
            }
        }
        return array
    }
    
    static func remove(at path: Pointer, in json: JSON) throws -> JSON {
        guard path.count > 0 else { return .null }
        
        switch json {
        case .object(var object):
            object = try remove(at: path, in: object)
            return .object(object)
        case .array(var array):
            array = try remove(at: path, in: array)
            return .array(array)
            
        case .string, .number, .bool, .null:
            throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
        }
    }
    
    static func add(value: JSON, at path: Pointer, in object: JSON.Object) throws -> JSON.Object {
        let token = path[0]
        var object = object
        if path.count == 1 {
            if object[token] == nil || object[token] == .null {
                object[token] = value
            } else {
                throw JSONPatchError.existingValue
            }
            
        } else {
            let childPath = Pointer(path.dropFirst())
            if let child = object[token] {
                object[token] = try add(value: value, at: childPath, in: child)
            } else {
                throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
            }
        }
        return object
    }
    
    static func add(value: JSON, at path: Pointer, in array: JSON.Array) throws -> JSON.Array {
        let token = path[0]
        var array = array
        if path.count == 1 {
            if let tokenIndex = getTokenIndex(for: token), tokenIndex >= 0, tokenIndex <= array.count {
                array.insert(value, at: tokenIndex)
            } else if token == "-" {
                array.append(value)
            } else {
                throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
            }
            
        } else {
            let childPath = Pointer(path.dropFirst())
            if let tokenIndex = getTokenIndex(for: token), tokenIndex >= 0, tokenIndex < array.count {
                array[tokenIndex] = try add(value: value, at: childPath, in: array[tokenIndex])
            } else if token == "-" {
                let document = try add(value: value, at: childPath, in: JSON.object([:]))
                array.append(document)
            } else {
                throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
            }
        }
        return array
    }
    
    static func add(value: JSON, at path: Pointer, in json: JSON) throws -> JSON {
        guard path.count > 0 else { return value }
        
        switch json {
        case .object(var object):
            object = try add(value: value, at: path, in: object)
            return .object(object)
        case .array(var array):
            array = try add(value: value, at: path, in: array)
            return .array(array)
            
        case .string, .number, .bool, .null:
            throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
        }
    }
    
    static func value(at path: Pointer, in object: JSON.Object) throws -> JSON {
        let token = path[0]
        if path.count == 1 {
            if let value = object[token] {
                return value
            } else {
                throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
            }
            
        } else {
            let childPath = Pointer(path.dropFirst())
            if let child = object[token] {
                return try value(at: childPath, in: child)
            } else {
                throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
            }
        }
    }
    
    static func value(at path: Pointer, in array: JSON.Array) throws -> JSON {
        let token = path[0]
        if path.count == 1 {
            if let tokenIndex = getTokenIndex(for: token), tokenIndex >= 0, tokenIndex < array.count {
                return array[tokenIndex]
            } else if token == "-", let last = array.last {
                return last
            } else {
                throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
            }

        } else {
            let childPath = Pointer(path.dropFirst())
            if let tokenIndex = getTokenIndex(for: token), tokenIndex >= 0, tokenIndex < array.count {
                return try value(at: childPath, in: array[tokenIndex])
            } else if token == "-", let last = array.last {
                return try value(at: childPath, in: last)
            } else {
                throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
            }
        }
    }
    
    static func value(at path: Pointer, in json: JSON) throws -> JSON {
        guard path.count > 0 else { return json }
        
        switch json {
        case .object(let object):
            return try value(at: path, in: object)
        case .array(let array):
            return try value(at: path, in: array)
            
        case .string, .number, .bool, .null:
            throw JSONPatchError.unreachablePath(JSONPatch.encodePointer(path))
        }
    }
}


extension JSONPatch {
    
    static func replace(value: JSON, at path: Pointer, in json: JSON) throws -> JSON {
        let removed = try remove(at: path, in: json)
        return try add(value: value, at: path, in: removed)
    }
    
    static func copy(from:Pointer, to path: Pointer, in json: JSON) throws -> JSON {
        let value = try value(at: from, in: json)
        let result = try add(value: value, at: path, in: json)
        return result
    }
    
    static func move(from:Pointer, to path: Pointer, in json: JSON) throws -> JSON {
        let value = try value(at: from, in: json)
        let removed = try remove(at: from, in: json)
        return try add(value: value, at: path, in: removed)
    }
    
    static func test(value: JSON, at path: Pointer, in json: JSON) throws -> JSON {
        let existing = try self.value(at: path, in: json)
        if existing == value {
            return json
        } else {
            throw JSONPatchError.failedTest
        }
    }
    
    static func execute(_ operation:JSONPatch.Operation, with json: JSON) -> Result<JSON, JSONPatchError> {
        guard operation.isLegal else {
            return .failure(.illegalOperation)
        }
        
        var result:JSON? = nil
        
        do {
            guard let path = try operation.pathPointer else { return .failure(.missingOperationPath)}
            let from = try operation.fromPointer
            switch operation.code {
            case .add:
                if let value = operation.value {
                    result = try add(value: value, at: path, in: json)
                }
            case .remove:
                result = try remove(at: path, in: json)
            case .replace:
                if let value = operation.value {
                    result = try replace(value: value, at: path, in: json)
                }
            case .copy:
                if let from = from {
                    result = try copy(from: from, to: path, in: json)
                }
            case .move:
                if let from = from {
                    result = try move(from: from, to: path, in: json)
                }
            case .test:
                if let value = operation.value {
                    result = try test(value: value, at: path, in: json)
                }
            case .unknown:
                return .failure(.illegalOperation)
            }
        } catch {
            if let patchError = error as? JSONPatchError {
                return .failure(patchError)
            } else {
                return .failure(.unknown(error))
            }
        }
        
        if let result = result {
            return .success(result)
        } else {
            return .failure(.illegalOperation)
        }
        
    }
    
    public func apply(to json: JSON) -> Result<JSON, JSONPatchError> {
        var result:Result<JSON, JSONPatchError> = .success(json)
        
        for operation in self {
            switch result {
            case .success(let json):
                result = JSONPatch.execute(operation, with: json)
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return result
    }
    
}
