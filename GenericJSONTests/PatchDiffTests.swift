//
//  PatchDiffTests.swift
//  GenericJSONTests
//
//  Created by Trystan Pfluger on 16/1/2023.
//

import XCTest
import GenericJSON

struct JSONPatchDiffTestRecord: CodableRecord {
    let source: JSON
    let target: JSON
    let patch: JSONPatch?
    let comment: String?
    let disabled: Bool?
}

typealias JSONPatchDiffTestRecords = [JSONPatchDiffTestRecord]

class PatchDiffTests: XCTestCase, RecordTestCaseProtocol, ObjcTestCaseProtocol {
    typealias Record = JSONPatchDiffTestRecord
    
    override class var defaultTestSuite: XCTestSuite {
        return RecordTestCase<JSONPatchDiffTestRecord>.buildTestSuite(for: "diff-tests.json",
                                                                           in: "diff-tests",
                                                                           suite: self,
                                                                           tester: self)
    }
    
    var index:Int?
    var filename:String?
    var record:Record?
    
    @objc func performTest() {
        
        guard let index = index else {
            XCTFail("Index not found for test")
            return
        }
        
        guard let record = record else {
            XCTFail("[\(index)] Record not found for test")
            return
        }

        let result = JSONPatch(from: record.source, to: record.target)
        let comment = record.comment ?? "no comment"

        if let patch = record.patch {
            XCTAssertEqual(result, patch, "[\(index)] Mismatching patches: \(comment)")
        }

        let executionResult = result.apply(to: record.source)
        switch executionResult {
        case .success(let json):
            XCTAssertEqual(record.target, json, "[\(index)] Patch creates bad result: \(comment)")
        case .failure(let error):
            XCTFail("[\(index)] \(comment): \(error)")
        }
    }

}
