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
    case unreachablePath
    case failedTest
    case existingValue
    case missingOperationPath
    case invalidPointerFormat(Int)
    case unknown(Error)
}
