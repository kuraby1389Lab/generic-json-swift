import XCTest
@testable import GenericJSON

class CodingTests: XCTestCase {
    
    @available(OSX 10.13, *)
    func testEncoding() throws {
        let json: JSON = [
            "num": 1,
            "str": "baz",
            "bool": true,
            "null": nil,
            "array": [],
            "obj": [:],
        ]
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encoded = try encoder.encode(json)
        let str = String(data: encoded, encoding: .utf8)!
        XCTAssertEqual(str, """
            {"array":[],"bool":true,"null":null,"num":1,"obj":{},"str":"baz"}
            """)
    }

    // ???: DOESNOT throw errors
    // func testFragmentEncoding() {
    //     let fragments: [JSON] = ["foo", 1, true, nil]
    //     for f in fragments {
    //         XCTAssertThrowsError(try JSONEncoder().encode(f))
    //     }
    // }

    func testDecoding() throws {
        let input = """
            {"array":[1],"num":1,"bool":true,"obj":{},"null":null,"str":"baz"}
            """
        let json = try! JSON(from: input)
        XCTAssertEqual(json, [
            "num": 1,
            "str": "baz",
            "bool": true,
            "null": nil,
            "array": [1],
            "obj": [:],
        ])
    }

    func testDecodingBool() throws {
        XCTAssertEqual(try JSON(from: "{\"b\":true}"), ["b":true])
        XCTAssertEqual(try JSON(from: "{\"b\":true}"), ["b":true])
        XCTAssertEqual(try JSON(from: "{\"n\":1}"), ["n":1])
    }

    func testEmptyCollectionDecoding() throws {
        XCTAssertEqual(try JSON(from: "[]"), [])
        XCTAssertEqual(try JSON(from: "{}"), [:])
    }

    func testDebugDescriptions() {
        let fragments: [JSON] = ["foo", 1, true, nil]
        let descriptions = fragments.map { $0.debugDescription }
        XCTAssertEqual(descriptions, ["\"foo\"", "1.0", "true", "null"])
    }
}
