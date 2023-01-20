import Foundation
import GenericJSON

let json: JSON = [
    "foo": "bar",
    "bar": 1,
    "empty": nil,
]

let str = encodeToString(json)

//: [Next](@next)
