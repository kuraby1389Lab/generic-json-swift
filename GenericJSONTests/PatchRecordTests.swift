//
//  PatchRecordTests.swift
//  GenericJSONTests
//
//  Created by Trystan Pfluger on 12/1/2023.
//

import Foundation
import XCTest
import GenericJSON

struct JSONPatchTestRecord: Codable {
    let doc: JSON
    let patch: [JSONPatch.Operation]
    let comment: String?
    let expected: JSON?
    let disabled: Bool?
    let error: String?
    
    var shouldFail:Bool { return error != nil }
}

typealias JSONPatchTestRecords = [JSONPatchTestRecord]

func testsDirectory(path: String = #file) -> URL {
    let url = URL(fileURLWithPath: path)
    let testsDir = url.deletingLastPathComponent()
    let res = testsDir.appendingPathComponent("json-patch-tests")
    return res
}

private func loadTestRecords(filename: String) throws -> JSONPatchTestRecords {
    let fileURL = testsDirectory().appendingPathComponent(filename)
    let data = try Data(contentsOf: fileURL)
    return try JSONDecoder().decode(JSONPatchTestRecords.self, from: data)
}

class PatchRecordTests: XCTestCase {
    
    class func buildTestSuite(for filename:String, class testSuiteClass: AnyClass) -> XCTestSuite {
        let suite = XCTestSuite(forTestCaseClass: testSuiteClass)
        if let records = try? loadTestRecords(filename: filename) {
            
            for (index,record) in records.enumerated() {
                let test = PatchRecordTests(selector: #selector(verifyRecord))
                test.record = record
                test.index = index
                test.filename = filename
                suite.addTest(test)
            }
        } else {
            let test = PatchRecordTests(selector: #selector(assertFailedSuiteLoad))
            test.filename = filename
            suite.addTest(test)
        }
        
        return suite
    }
    
    var filename:String!
    var record:JSONPatchTestRecord!
    var index:Int!
    
    @objc func verifyRecord() {
        // skip disabled records
        guard record.disabled != true else { return }
        
        let index = index!
        let result = JSONPatch.execute(record.patch, with: record.doc)
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
    
    @objc func assertFailedSuiteLoad() {
        XCTFail("Unable to load test records from '\(filename!)'")
    }
}

class PatchOfficalMainTests: XCTestCase {
    override class var defaultTestSuite: XCTestSuite {
        return PatchRecordTests.buildTestSuite(for: "tests.json", class: self)
    }
}

class PatchOfficalRFCTests: XCTestCase {
    override class var defaultTestSuite: XCTestSuite {
        return PatchRecordTests.buildTestSuite(for: "spec_tests.json", class: self)
    }
}
