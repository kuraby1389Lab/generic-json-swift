//
//  JSONDecoder+FromString.swift
//  GenericJSONTests
//
//  Created by Trystan Pfluger on 12/1/2023.
//

import Foundation

extension JSONDecoder {
    func decode<T>(_ type: T.Type, from string: String) throws -> T where T : Decodable {
        return try decode(type, from: string.data(using: .utf8)!)
    }
    
    static func decode<T>(_ type: T.Type, from string: String) throws -> T where T : Decodable {
        return try JSONDecoder().decode(type, from: string.data(using: .utf8)!)
    }
}
