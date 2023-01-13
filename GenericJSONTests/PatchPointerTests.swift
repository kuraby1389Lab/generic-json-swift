//
//  PatchPointerTests.swift
//  GenericJSONTests
//
//  Created by Trystan Pfluger on 11/1/2023.
//

import XCTest
import GenericJSON

class PatchPointerTests: XCTestCase {
    
    func testPointerDecoding() {
        XCTAssertThrowsError(try JSONPatch.decodePointer(from: "a"))
        XCTAssertEqual(try? JSONPatch.decodePointer(from: "/abc/def"), ["abc","def"])
    }

    func testPointerEncoding() {
        XCTAssertEqual(JSONPatch.encodePointer(["abc","def"]), "/abc/def")
        XCTAssertEqual(JSONPatch.encodePointer(["a/b/c","d~e~f"]), "/a~1b~1c/d~0e~0f")
    }
}
