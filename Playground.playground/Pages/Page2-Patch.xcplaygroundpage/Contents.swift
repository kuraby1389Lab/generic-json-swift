//: [Previous](@previous)

import Foundation
import GenericJSON

private let testDelimiter = "##########################"

func testDiff(_ testName: String, source:JSON, target: JSON) {
    print("\(testDelimiter)\n# beginning '\(testName)':")
    print("source:\n",encodeToString(source, pretty: false))
    print("target:\n",encodeToString(target, pretty: false))
    encodeToString(target)
    
    let patch = JSONPatch(from: source, to: target)
    
    printArray("patch", patch)
    
    switch patch.apply(to: source) {
    case .success(let output):
        print("output from patch:\n", encodeToString(output, pretty: false))
        
        if output == target {
            print("patch output matches target")
        } else {
            print("*** Error: patch output does not equal target")
        }
        
    case .failure(let error):
        print("*** Error: could not apply patch - \(error.localizedDescription)")
    }
    
    print("# finished '\(testName)'\n\(testDelimiter)")
}

let sourceArray:JSON = ["one",1,nil,["nested":["number":5,"equal":true]]]
let targetArray:JSON = [["nested":["bool":true,"equal":true]],0, "one", "two",1,2,3]

let sourceObject:JSON = [
    "foo": "bar",
    "bar": 1,
    "empty": nil,
    "hello":["hello"]
]

let targetObject:JSON = [
    "foo": "foo",
    "goodbye":["hello"],
    "bar": 0,
    "empty": nil
]

testDiff("arrays", source: sourceArray, target: targetArray)
testDiff("objects", source: sourceObject, target: targetObject)

testDiff("remove all items from array", source: sourceArray, target: [])

testDiff("different types", source: sourceArray, target: targetObject)

testDiff("different types (primitive)", source: .bool(true), target: .string("hello"))

testDiff("change type (empty)", source: [:], target: [])

//: [Next](@next)
