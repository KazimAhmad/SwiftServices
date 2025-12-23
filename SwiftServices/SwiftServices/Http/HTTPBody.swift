//
//  HTTPBody.swift
//  SwiftServices
//
//  Created by Kazim Ahmad on 23/12/2025.
//

import Foundation

enum HTTPBody {
    case json(Encodable)
    //MARK: -this exercise only needs the json type but i am including the form and multiform types as well
    case formData([String: String?])
    case multiFormData([String: Any?])
    
    var formData: (data: Data, boundary: String) {
        switch self {
        case .formData(let dict):
            var data: [String] = []
            for (k, v) in dict {
                if let v = v {
                    data.append(k + "=" + (v.addingPercentEncodingForURLFormValue ?? ""))
                }
            }
            
            return (data.joined(separator: "&").data(using: .utf8)!, "")
        case .multiFormData(let dict):
            let boundary = UUID().uuidString
            var data = Data()
            
            for (k, v) in dict {
                if let value = v as? String {
                    var fieldString = "--\(boundary)\r\n"
                    fieldString += "Content-Disposition: form-data; name=\"\(k)\"\r\n"
                    fieldString += "Content-Type: text/plain; charset=utf-8\r\n"
                    fieldString += "Content-Transfer-Encoding: binary\r\n"
                    fieldString += "\r\n"
                    fieldString += value
                    fieldString += "\r\n"
                    data += fieldString.data(using: .utf8)!
                } else if let value = v as? Data {
                    var fieldString = "--\(boundary)\r\n"
                    fieldString += "Content-Disposition: form-data; name=\"\(k)\"; filename=\"\(UUID().uuidString).jpg\"\r\n"
                    fieldString += "Content-Type: image/jpeg\r\n"
                    fieldString += "Content-Transfer-Encoding: binary\r\n"
                    fieldString += "\r\n"
                    data += fieldString.data(using: .utf8)!
                    data += value
                    data += "\r\n".data(using: .utf8)!
                }
            }
            
            let boundaryString = "--\(boundary)--"
            data += boundaryString.data(using: .utf8)!
            
            return (data, boundary)
        default:
            return (Data(), "")
        }
    }
    
    func jsonData(_ encoder: JSONEncoder) -> Data? {
        switch self {
        case .json(let object):
            return try? encoder.encode(object)
        default:
            return nil
        }
    }
}
