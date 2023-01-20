//
//  JSONPatch+Match.swift
//  GenericJSON
//
//  Created by Trystan Pfluger on 18/1/2023.
//

import Foundation

private extension JSON {
    var contentLength: Int {
        return (try? JSONEncoder().encode(self))?.count ?? 0
    }
    
    var childCount: Int {
        switch self {
        case .object(let sourceObject):
            return sourceObject.values.reduce(sourceObject.count, { $0 + $1.childCount })
        case .array(let sourceArray):
            return sourceArray.reduce(sourceArray.count, { $0 + $1.childCount })
            
        case .string, .number, .bool, .null:
            return 0
        }
    }
}

public enum JSONArrayMatchCategory:Int, Comparable, Codable {
    case none
    case contents
    case exact
    
    public static func < (lhs:Self, rhs:Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public enum JSONArrayMatchResultPath: Comparable, Equatable, Codable {
    case index(Int)
    case key(String)
    case `nil`
    
    public static func < (lhs:Self, rhs:Self) -> Bool {
        switch (lhs, rhs) {
        case (.nil, .nil):
            return false
        case (.nil, _):
            return false
        case (_, .nil):
            return true
        case let(.index(lhsIndex), .index(rhsIndex)):
            return lhsIndex < rhsIndex
        case let(.key(lhsKey), .key(rhsKey)):
            return lhsKey < rhsKey
        case (.index, .key):
            return true
        case (.key, .index):
            return true
        }
    }
    
    var keyValue:String? {
        guard case let Self.key(key) = self else { return nil }
        return key
    }
    
    var indexValue:Int? {
        guard case let Self.index(index) = self else { return nil }
        return index
    }
    
    static func areSortable(_ lhs:Self, _ rhs:Self) -> Bool {
        return lhs.indexValue != nil && rhs.indexValue != nil
    }
}

public struct JSONArrayMatchResult:Equatable, CustomStringConvertible, Codable {
    public static let noneAffinity:Int = -100
    public static let exactAffinity:Int = 500
    
    public let category:JSONArrayMatchCategory
    public let affinity:Int
    public let length:Int
    public let children:Int
    
    public let source:JSONArrayMatchResultPath
    public let target:JSONArrayMatchResultPath
    
    
    public var description: String {
        return "Result['\(source)' -> '\(target)'](\(category), affinity:\(affinity), children:\(children), length:\(length))"
    }
}

public extension JSONArrayMatchResult {
    static func none(source: JSONArrayMatchResultPath = .nil, target: JSONArrayMatchResultPath = .nil) -> Self {
        return .init(category: .none, affinity: Self.noneAffinity, length: 0, children: 0, source: source, target: target)
    }
    static func contents(_ affinity: Int, length: Int, children:Int, source: JSONArrayMatchResultPath = .nil, target: JSONArrayMatchResultPath = .nil) -> Self {
        return .init(category: .contents, affinity: affinity, length: 0, children: children, source: source, target: target)
    }
    static func exact(length: Int, children:Int, source: JSONArrayMatchResultPath = .nil, target: JSONArrayMatchResultPath = .nil) -> Self {
        return .init(category: .exact, affinity: Self.exactAffinity, length: length, children: children, source: source, target: target)
    }
}

private extension Optional where Wrapped: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        if let rhs = rhs {
            if let lhs = lhs {
                return lhs < rhs
            } else {
                return true
            }
        } else {
            return false
        }
    }
}

public extension Array where Element == JSONArrayMatchResult {
    
    func sortedByPriority() -> Self {
        sorted { lhs,rhs in
            guard lhs.affinity == rhs.affinity else { return lhs.affinity > rhs.affinity }
            guard lhs.children == rhs.children else { return lhs.children > rhs.children }
            guard lhs.length == rhs.length else { return lhs.length > rhs.length }
            guard lhs.target == rhs.target else { return lhs.target < rhs.target }
            guard lhs.source == rhs.source else { return lhs.source < rhs.source }
            return lhs.category > rhs.category
        }
    }
    
    func determineBest() -> Self {
        var matchedSources:[JSONArrayMatchResultPath] = []
        var matchedTargets:[JSONArrayMatchResultPath] = []
        let sorted = self.sortedByPriority()
        var results:[JSONArrayMatchResult] = []
        for result in sorted where !matchedSources.contains(result.source) && !matchedTargets.contains(result.target) {
            results.append(result)
            matchedSources.append(result.source)
            matchedTargets.append(result.target)
        }
        return results
    }
    
    var affinity:Int {
        reduce(0) { $0 + $1.affinity }
    }
}

public extension JSONPatch {
    
    static func match(targets: JSON.Object, with source: JSON.Object?) -> [JSONArrayMatchResult] {
        guard let source = source else { return [] }
        
        var results:[JSONArrayMatchResult] = []
        for (targetKey, targetValue) in targets {
            results.append(match(target: targetValue, at: .key(targetKey), in: source))
        }
        //print("\nOBJ results.sortedByPriority: ",results.sortedByPriority())
        // print("\nOBJ results.determineBest: ",results.determineBest())
        return results.determineBest()
    }
    
    static func match(target: JSON, at targetPath: JSONArrayMatchResultPath, in source: JSON.Object?) -> JSONArrayMatchResult {
        guard let source = source else { return .none() }
        
        
        var results:[JSONArrayMatchResult] = []
        for (sourceKey, sourceValue) in source {
            results.append(match(target: target, with: sourceValue, targetPath: targetPath, sourcePath: .key(sourceKey)))
        }
        
        if let best = results.determineBest().first, best.category != .none {
            return best
        } else {
            return .none(target: targetPath)
        }
    }
    
    static func match(targets: JSON.Array, with source: JSON.Array?) -> [JSONArrayMatchResult] {
        guard let source = source else { return [] }
        
        var results:[JSONArrayMatchResult] = []
        for (index, target) in targets.enumerated() {
            results.append(contentsOf: match(target: target, at: .index(index), in: source))
        }
        // print("\nARR results.sortedByPriority: ",results.sortedByPriority())
        // print("\nARR results.determineBest: ",results.determineBest())
        return results.determineBest()
    }
    
    static func match(target: JSON, at targetPath: JSONArrayMatchResultPath, in source: JSON.Array) -> [JSONArrayMatchResult] {
        guard source.count > 0 else { return [] }
        var results:[JSONArrayMatchResult] = []
        for (sourceIndex,element) in source.enumerated() {
            if element == target {
                results.append(.exact(length: target.contentLength, children: target.childCount, source: .index(sourceIndex), target: targetPath))
            } else if element.contentType == target.contentType {
                let contentMatchResults:[JSONArrayMatchResult]
                switch target {
                case .object(let targetObject):
                    contentMatchResults = match(targets: targetObject, with: element.objectValue)
                case .array(let targetArray):
                    contentMatchResults = match(targets: targetArray, with: element.arrayValue)
                case .string, .number, .bool, .null:
                    contentMatchResults = []
                }
                results.append(.contents(contentMatchResults.affinity,
                                         length: target.contentLength,
                                         children: target.childCount,
                                         source: .index(sourceIndex),
                                         target: targetPath))
            }
        }
        if results.count == 0 {
            results.append(.none(source: .nil, target: targetPath))
        }
        return results.determineBest()
    }
    
    static func match(target:JSON, with source:JSON, targetPath: JSONArrayMatchResultPath = .nil, sourcePath: JSONArrayMatchResultPath = .nil) -> JSONArrayMatchResult {
        guard target != source else { return .exact(length: target.contentLength, children: target.childCount, source: sourcePath, target: targetPath) }
        
        if source.contentType == target.contentType {
            let contentMatchResults:[JSONArrayMatchResult]
            switch target {
            case .object(let targetObject):
                contentMatchResults = match(targets: targetObject, with: source.objectValue)
            case .array(let targetArray):
                contentMatchResults = match(targets: targetArray, with: source.arrayValue)
            case .string, .number, .bool, .null:
                contentMatchResults = []
            }
            return .contents(contentMatchResults.affinity,
                             length: target.contentLength,
                             children: target.childCount,
                             source: sourcePath,
                             target: targetPath)
        } else {
            return .none(source: sourcePath, target: targetPath)
        }
        
    }
    
}
