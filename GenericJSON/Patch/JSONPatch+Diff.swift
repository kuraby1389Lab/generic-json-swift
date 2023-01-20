//
//  JSONPatch+Diff.swift
//  GenericJSON
//
//  Created by Trystan Pfluger on 16/1/2023.
//

import Foundation

public extension JSON {
    enum ContentType: String, Equatable {
        case string
        case number
        case object
        case array
        case bool
        case null
    }
    
    var contentType: ContentType {
        switch self {
        case .string:
            return .string
        case .number:
            return .number
        case .object:
            return .object
        case .array:
            return .array
        case .bool:
            return .bool
        case .null:
            return .null
        }
    }
}

public extension JSONPatch {
    
    static func difference(from source: JSON.Object, to target: JSON.Object?, path:JSONPatch.Pointer) -> JSONPatch {
        guard let target = target, source != target else { return JSONPatch() }
        var patch = JSONPatch()
        
        let matches = match(targets: target, with: source)
        
        var targetKeys = Set(target.keys)
        var sourceKeys = Set(source.keys)
        
        for match in matches where match.category != .none {
            if let targetKey = match.target.keyValue,
               let sourceKey = match.source.keyValue,
               targetKeys.contains(targetKey),
               sourceKeys.contains(sourceKey)
            {
                targetKeys.remove(targetKey)
                sourceKeys.remove(sourceKey)
                
                if targetKey != sourceKey {
                    patch.append(.move(path: path.appending(targetKey), from: path.appending(sourceKey)))
                }
                
                if case JSONArrayMatchCategory.contents = match.category,
                   let sourceValue = source[sourceKey],
                   let targetValue = target[targetKey] {
                   patch.append(contentsOf: difference(from: sourceValue, to: targetValue, path: path.appending(targetKey)))
                }
            }
        }
        
        for targetKey in targetKeys.sorted() {
            if let targetValue = target[targetKey] {
                // print("adding", targetKey)
                patch.append(.add(path: path.appending(targetKey), value: targetValue))
            }
        }
        
        for sourceKey in sourceKeys.sorted() {
            patch.append(.remove(path: path.appending(sourceKey)))
        }
        
        return patch
    }
    
    static func difference(from source: JSON.Array, to target: JSON.Array?, path:JSONPatch.Pointer) -> JSONPatch {
        guard let target = target, source != target else { return JSONPatch() }
        var patch = JSONPatch()
        
        let matches = match(targets: target, with: source)
        
        var sourceIndices = [Int](0..<(source.count))
        var targetIndices = [Int](0..<(target.count))
        
        for match in matches {
            if let targetIndex = match.target.indexValue,
               let sourceIndex = match.source.indexValue,
               targetIndices.contains(targetIndex),
               sourceIndices.contains(sourceIndex),
               targetIndex < source.count {
                sourceIndices.removeAll(where: { $0 == targetIndex || $0 == sourceIndex })
                targetIndices.removeAll(where: { $0 == targetIndex })
                if targetIndex < sourceIndex {
                } else if targetIndex > sourceIndex {
                    
                }
                if targetIndex != sourceIndex {
                    patch.append(.copy(path: path.appending(targetIndex), from: path.appending(sourceIndex)))
                    patch.append(.remove(path: path.appending(targetIndex+1)))
                }
                
                if case JSONArrayMatchCategory.contents = match.category {
                    patch.append(contentsOf: difference(from: source[sourceIndex], to: target[targetIndex], path: path.appending(targetIndex)))
                }
            }
        }
        
        for index in 0..<Swift.min(target.count, source.count) where targetIndices.contains(index) || sourceIndices.contains(index) {
            patch.append(.replace(path: path.appending(index), value: target[index]))
        }
        
        if source.count > target.count {
            var removalPatch = JSONPatch()
            
            for index in target.count..<source.count {
                removalPatch.append(.remove(path: path.appending(index)))
            }

            patch.append(contentsOf: removalPatch.reversed())
        } else if target.count > source.count {
            for index in source.count..<target.count where targetIndices.contains(index) {
                patch.append(.add(path: path.appending("-"), value: target[index]))
            }
        }
        
        return patch
    }
    
    static func difference(from source: JSON, to target: JSON, path:JSONPatch.Pointer) -> JSONPatch {
        guard source != target else { return JSONPatch() }
        var patch = JSONPatch()
        guard source.contentType == target.contentType else {
            patch.append(.replace(path: JSONPatch.encodePointer(path), value: target))
            return patch
        }
        
        switch source {
        case .object(let sourceObject):
            patch.append(contentsOf: difference(from: sourceObject, to: target.objectValue, path: path))
        case .array(let sourceArray):
            patch.append(contentsOf: difference(from: sourceArray, to: target.arrayValue, path: path))
            
        case .string, .number, .bool, .null:
            patch.append(.replace(path: path, value: target))
        }
        
        return patch
    }
    
    init(from source: JSON, to target: JSON) {
        self = JSONPatch.difference(from: source, to: target, path: [])
    }
    
}
