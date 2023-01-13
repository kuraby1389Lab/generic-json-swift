//
//  PatchOperationTests.swift
//  GenericJSONTests
//
//  Created by Trystan Pfluger on 12/1/2023.
//

import XCTest
import GenericJSON

class PatchOperationTests: XCTestCase {
    
    typealias Operation = JSONPatch.Operation
    
    func testOperationCodable() {
        
        let operationString = """
                              { "op": "move", "from": "/biscuits", "path": "/cookies", "value": "Chocolate Digestive" }
                              """
        let operation = Operation(.move, path: "/cookies", from: "/biscuits", value: .string("Chocolate Digestive"))
        
        XCTAssertEqual(try JSONDecoder.decode(Operation.self, from: operationString), operation)
    }
    
    func testOperationLegality() {
        
        XCTAssertFalse(Operation(.unknown, path: "/", value: .string("blah")).isLegal)
        XCTAssertFalse(Operation(.add, value: .string("blah")).isLegal)
        
        XCTAssertFalse(Operation(.add, path: "/", from: "/", value: .string("blah")).isLegal)
        XCTAssertFalse(Operation(.add, path: "/", from: "/").isLegal)
        XCTAssertTrue(Operation(.add, path: "/", value: .string("blah")).isLegal)
        
        XCTAssertFalse(Operation(.remove, path: "/", from: "/", value: .string("blah")).isLegal)
        XCTAssertFalse(Operation(.remove, path: "/", from: "/").isLegal)
        XCTAssertFalse(Operation(.remove, path: "/", value: .string("blah")).isLegal)
        XCTAssertTrue(Operation(.remove, path: "/").isLegal)
        
        XCTAssertFalse(Operation(.replace, path: "/", from: "/", value: .string("blah")).isLegal)
        XCTAssertFalse(Operation(.replace, path: "/", from: "/").isLegal)
        XCTAssertTrue(Operation(.replace, path: "/", value: .string("blah")).isLegal)
        
        XCTAssertFalse(Operation(.copy, path: "/", from: "/", value: .string("blah")).isLegal)
        XCTAssertFalse(Operation(.copy, path: "/", value: .string("blah")).isLegal)
        XCTAssertTrue(Operation(.copy, path: "/", from: "/").isLegal)
        
        XCTAssertFalse(Operation(.move, path: "/", from: "/", value: .string("blah")).isLegal)
        XCTAssertFalse(Operation(.move, path: "/", value: .string("blah")).isLegal)
        XCTAssertTrue(Operation(.move, path: "/", from: "/").isLegal)
        
        XCTAssertFalse(Operation(.test, path: "/", from: "/", value: .string("blah")).isLegal)
        XCTAssertFalse(Operation(.test, path: "/", from: "/").isLegal)
        XCTAssertTrue(Operation(.test, path: "/", value: .string("blah")).isLegal)
        
    }

}

