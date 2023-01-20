//
//  PatchOfficialTests.swift
//  GenericJSONTests
//
//  Created by Trystan Pfluger on 12/1/2023.
//

import Foundation
import XCTest
import GenericJSON

struct OfficialPatchTestRecord: CodableRecord {
    let doc: JSON
    let patch: JSONPatch
    let comment: String?
    let expected: JSON?
    let disabled: Bool?
    let error: String?
    
    var shouldFail:Bool { return error != nil }
}

typealias JSONPatchTestRecords = [OfficialPatchTestRecord]

class PatchOfficialTests: XCTestCase, RecordTestCaseProtocol, ObjcTestCaseProtocol {
    typealias Record = OfficialPatchTestRecord
    
    var index:Int?
    var filename:String?
    var record:Record?

    @objc func performTest() {
        
        let record = record!
        let index = index!

        let result = record.patch.apply(to: record.doc)
        // JSONPatch.execute(record.patch, with: record.doc)
        let comment = record.comment ?? "no comment"

        switch result {
        case .success(let jsonResult):
            if record.shouldFail {
                XCTFail("[\(index)] Patch execution should fail: \(comment)")
            } else {
                XCTAssertEqual(jsonResult, record.expected, "[\(index)] \(comment)")
            }
        case .failure(let error):
            if !record.shouldFail {
                XCTFail("[\(index)] \(comment): \(error)")
            }
        }
    }
}

private let directory = "json-patch-tests"

class PatchOfficalMainTests: XCTestCase {
    override class var defaultTestSuite: XCTestSuite {
        return RecordTestCase<OfficialPatchTestRecord>.buildTestSuite(for: "tests.json",
                                                                       in: directory,
                                                                       suite: self,
                                                                       tester: PatchOfficialTests.self)
    }
}

class PatchOfficalRFCTests: XCTestCase {
    override class var defaultTestSuite: XCTestSuite {
        return RecordTestCase<OfficialPatchTestRecord>.buildTestSuite(for: "spec_tests.json",
                                                                       in: directory,
                                                                       suite: self,
                                                                       tester: PatchOfficialTests.self)
    }
}
