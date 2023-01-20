//
//  TestUtilities.swift
//  GenericJSONTests
//
//  Created by Trystan Pfluger on 16/1/2023.
//

import Foundation
import XCTest
import GenericJSON

protocol CodableRecord: Codable {
    var disabled:Bool? { get }
}

protocol RecordTestCaseProtocol {
    associatedtype Record: CodableRecord
    var index: Int? { get set }
    var record: Record? { get set }
    var filename: String? { get set }
}

@objc protocol ObjcTestCaseProtocol {
    func performRecordTest()
}

func projectDirectoryURL(for name: String, path: String = #file) -> URL {
    let url = URL(fileURLWithPath: path)
    let testsDir = url.deletingLastPathComponent().deletingLastPathComponent()
    let res = testsDir.appendingPathComponent(name)
    return res
}

func loadCodableRecords<Record: CodableRecord>(from filename: String, in directory: String) throws -> [Record] {
    let directoryURL = projectDirectoryURL(for: directory)
    let fileURL = directoryURL.appendingPathComponent(filename)
    let data = try Data(contentsOf: fileURL)
    return try JSONDecoder().decode([Record].self, from: data)
}

class RecordTestCase<Record: CodableRecord>: XCTestCase, RecordTestCaseProtocol, ObjcTestCaseProtocol {
    
    static func buildTestSuite<TestCase>(for filename:String, in directory: String, suite testSuiteClass: AnyClass, tester: TestCase.Type) -> XCTestSuite where TestCase: RecordTestCaseProtocol, TestCase: ObjcTestCaseProtocol, TestCase: XCTestCase, TestCase.Record == Record {
        let suite = XCTestSuite(forTestCaseClass: testSuiteClass)
        
        do {
            var testCount:Int = 0
            let records:[Record] = try loadCodableRecords(from: filename, in: directory)
            for (index,record) in records.enumerated() {
                // skip disabled records
                if record.disabled == true { continue }
                var test = TestCase(selector: #selector(TestCase.performRecordTest))
                test.record = record
                test.index = index
                test.filename = filename
                suite.addTest(test)
                testCount += 1
            }
            if records.count == 0 {
                let failedEmptyRecords = RecordTestCase(selector: #selector(assertFailedMessage))
                failedEmptyRecords.message = "No test records found in '\(filename)'"
                suite.addTest(failedEmptyRecords)
            } else if testCount == 0 {
                let failedEmptyRecords = RecordTestCase(selector: #selector(assertFailedMessage))
                failedEmptyRecords.message = "All test records disabled in '\(filename)'"
                suite.addTest(failedEmptyRecords)
            }
        } catch {
            let failedLoadingMessage = RecordTestCase(selector: #selector(assertFailedMessage))
            failedLoadingMessage.message = "Error loading '\(filename)': \(error)"
            suite.addTest(failedLoadingMessage)
        }
        
        return suite
    }
    
    var index: Int?
    var record: Record?
    var filename: String?
    
    func performRecordTest() {
        // meant for override
    }
    
    var message:String!
    
    @objc func assertFailedMessage() {
        XCTFail(message!)
    }
}
