//
//  JSONPatch+Pointer.swift
//  GenericJSON
//
//  Created by Trystan Pfluger on 11/1/2023.
//

import Foundation

extension JSONPatch {
    public typealias Token = String
    public typealias Pointer = [Token]
    
    public static func decodePointer(from string:String) throws -> Pointer {
        guard !string.isEmpty else { return [] }
        var tokens:[Token] = []
        var partialToken:String = ""
        var escaped: Bool = false
        var character: Character
        for i in 0..<string.count {
            let index = string.index(string.startIndex, offsetBy: i)
            character = string[index]
            if i == 0 {
                // First character must be foward slash, otherwise throw
                if character == "/" {
                    continue
                } else {
                    throw JSONPatchError.invalidPointerFormat(i)
                }
            } else if escaped {
                escaped = false
                // Check whether escaping is valid, otherwise throw
                if character == "0" {
                    partialToken.append("~")
                } else if character == "1" {
                    partialToken.append("/")
                } else {
                    throw JSONPatchError.invalidPointerFormat(i)
                }
            } else if character == "/" {
                // Move to the next token
//                if partialToken.isEmpty { throw JSONPatchError.invalidPointerFormat(string.endIndex) }
                tokens.append(partialToken)
                partialToken = ""
            } else if character == "~" {
                escaped = true
            } else {
                // Append the current character to the partial token
                partialToken.append(character)
            }
        }
        if !escaped {
            tokens.append(partialToken)
        } else {
            throw JSONPatchError.invalidPointerFormat(string.count - 1)
        }
        return tokens
    }
    
    public static func encodePointer(_ pointer:Pointer) -> String {
        var result:[String] = []
        for token in pointer {
            result.append(token
                .replacingOccurrences(of: "~", with: "~0")
                .replacingOccurrences(of: "/", with: "~1"))
        }
        
        if result.count > 0 {
            return "/" + result.joined(separator: "/")
        } else {
            return ""
        }
    }
}
