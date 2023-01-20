import Foundation
import GenericJSON

@discardableResult
public func encodeToString<C:Encodable>(_ codable:C, pretty:Bool = true) -> String {
    let encoder = JSONEncoder()
    if pretty { encoder.outputFormatting = .prettyPrinted }
    guard let data = try? encoder.encode(codable) else { return "error" }
    return String(data: data, encoding: .utf8) ?? "nil"
}

public func handleResult<C:Encodable, E: Error>(_ result:Result<C, E>, handleSuccess: @escaping ((C)->Void)) {
    switch result {
    case .success(let success):
        handleSuccess(success)
    case .failure(let error):
        print("Error:",error.localizedDescription)
    }
}

public func printArray<Element>(_ name: String? = nil, _ array:Array<Element>) {
    if let name = name {
        print("\(name) = (\(array.count))[")
    } else {
        print("(\(array.count))[")
    }
    for (index,element) in array.enumerated() {
        let printString = String(format: " %02d:\t%@", index, "\(element)")
        print(printString)
    }
    print("]")
}
