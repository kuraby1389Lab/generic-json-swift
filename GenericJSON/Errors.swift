//
//  Errors.swift
//  GenericJSON
//
//  Created by Trystan Pfluger on 12/1/2023.
//

import Foundation

public enum JSONError: Error {
    case decodingFailed
}

public enum JSONPatchError: Error {
    case illegalOperation
    case unreachablePath(String)
    case failedTest
    case existingValue
    case missingOperationPath
    case invalidPointerFormat(Int)
    case unknown(Error)
}

extension JSONPatchError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .illegalOperation:
            return "Illegal operation"
        case .unreachablePath(let pointer):
            return "Unreachable path: '\(pointer)'"
        case .failedTest:
            return "Failed test"
        case .existingValue:
            return "Existing value"
        case .missingOperationPath:
            return "Missing operation path"
        case .invalidPointerFormat(let index):
            return "Invalid pointer format at index \(index)"
        case .unknown(let error):
            return "Unknown error occurred: \(error.localizedDescription)"
        }
    }
}
