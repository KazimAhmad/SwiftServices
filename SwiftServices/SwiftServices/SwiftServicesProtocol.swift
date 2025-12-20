//
//  Persistence.swift
//  RickAndMorty
//
//  Created by Kazim Ahmad on 21/10/2025.
//

import Foundation

protocol SwiftServicesProtocol {
    var session: URLSession { get }
    var encoder: JSONEncoder { get }
    var decoder: JSONDecoder { get }
    var errorType: (Codable & Error).Type? { get }
        
    // File not found => WSError.notConnected
    var previewsStatucCode: Int { set get }
    // Delay request in seconds
    var previewsSleepSeconds: TimeInterval { set get }
    
    func request<T: Decodable>(_ path: String,
                               method: HTTPMethod,
                               query: [String: Any]?,
                               body: HTTPBody?,
                               headers: [String: String]?,
                               validate: Range<Int>,
                               cachePolicy: URLRequest.CachePolicy?,
                               retry: Bool) async throws -> T
    
    func request(_ path: String,
                 method: HTTPMethod,
                 query: [String: Any]?,
                 body: HTTPBody?,
                 headers: [String: String]?,
                 validate: Range<Int>,
                 retry: Bool) async throws
    
    //MARK: -Interceptor to do stuff right before request is going through
    func willSendRequest(_ request: inout URLRequest) async throws
    //MARK: -In case of retry if an error occurs
    func shouldRetry(withError error: Error) async -> Bool
    
    func didReceiveData(_ data: inout Data, request: URLRequest) async throws
}

//MARK: this is the implementation of the web services protocol as an extension
extension SwiftServicesProtocol {
    func request<T: Decodable>(_ path: String,
                               method: HTTPMethod = .get,
                               query: [String: Any]? = nil,
                               body: HTTPBody? = nil,
                               headers: [String: String]? = nil,
                               validate: Range<Int> = 200..<300,
                               cachePolicy: URLRequest.CachePolicy? = .useProtocolCachePolicy,
                               retry: Bool = true) async throws -> T {
        let url = URL(string: path)!
        
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw URLError(.badURL) }
        if let query = query {
            if !query.isEmpty {
                let percentEncodedQuery = (components.percentEncodedQuery.map { $0 + "&" } ?? "") + queryOfReq(query)
                components.percentEncodedQuery = percentEncodedQuery
            }
        }
        guard let url = components.url else { throw URLError(.badURL) }
        
        var req = URLRequest(url: url, cachePolicy: cachePolicy ?? .useProtocolCachePolicy)
        req.httpMethod = method.rawValue
        
        headers?.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        if cachePolicy == nil {
            req.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        }
        
        switch body {
        case .json:
            req.httpBody = body?.jsonData(encoder)
        case .formData:
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = body?.formData.data
        case .multiFormData:
            if let formData = body?.formData {
                req.setValue("multipart/form-data; boundary=\(formData.boundary)", forHTTPHeaderField: "Content-Type")
                req.setValue("\(formData.data.count)", forHTTPHeaderField: "Content-Length")
                req.httpBody = formData.data
            }
        default:
            break
        }
        
        do {
            return try await doRequest(req, validate: validate)
        } catch {
#if DEV
            print("[Error] \(error)")
#endif
            guard retry else { throw error }
            guard await shouldRetry(withError: error) else { throw error }
            return try await doRequest(req, validate: validate)
        }
    }
    
    func request(_ path: String,
                 method: HTTPMethod = .get,
                 query: [String: Any]? = nil,
                 body: HTTPBody? = nil,
                 headers: [String: String]? = nil,
                 validate: Range<Int> = 200..<300,
                 retry: Bool = true) async throws {
        let _: HTTPNoReply = try await request(path,
                                               method: method,
                                               query: query,
                                               body: body,
                                               headers: headers,
                                               retry: retry)
    }
    
    private func doRequest<T: Decodable>(_ request: URLRequest, validate: Range<Int>) async throws -> T {
        var request = request
        try await willSendRequest(&request)
        
#if DEV
        print(request.cURLDescription())
#endif
        
        var (data, response): (Data, URLResponse)
        
        do {
            (data, response) = try await session.data(for: request)
        } catch URLError.cancelled {
            throw CancellationError()
        } catch URLError.dataNotAllowed, URLError.notConnectedToInternet {
            throw SSError.notConnected
        } catch URLError.timedOut {
            throw SSError.timeOut
        } catch {
            throw SSError.undefined
        }
        
#if DEV
        print("[Response] \(response)")
        print("[Response Body] \(String(data: data, encoding: .utf8) ?? "(empty)")")
#endif

        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        guard validate.contains(httpResponse.statusCode) else {
            if let errorType {
                throw try decoder.decode(errorType, from: data)
            } else {
                throw HTTPError(statusCode: httpResponse.statusCode, data: data)
            }
        }
        
        if T.self is HTTPNoReply.Type {
            return HTTPNoReply() as! T
        }
        
        if data.isEmpty || httpResponse.statusCode == 204 {
            throw HTTPNoContent()
        }
        
        if T.self is String.Type, let string = String(decoding: data, as: UTF8.self) as? T {
            return string
        }
        
        try await didReceiveData(&data, request: request)
        
        return try decoder.decode(T.self, from: data)
    }
    
    func willSendRequest(_ request: inout URLRequest) async throws { }
    func didReceiveData(_ data: inout Data, request: URLRequest) async throws { }
    func shouldRetry(withError error: Error) async -> Bool { return false }
    
    func invalidateCache() {
        session.configuration.urlCache?.removeAllCachedResponses()
    }
}

//MARK: -To handle the Any type of query
public enum ArrayEncoding {
    case brackets, noBrackets

    func encode(key: String) -> String {
        switch self {
        case .brackets:
            return "\(key)[]"
        case .noBrackets:
            return key
        }
    }
}

public enum BoolEncoding {
    case numeric, literal

    func encode(value: Bool) -> String {
        switch self {
        case .numeric:
            return value ? "1" : "0"
        case .literal:
            return value ? "true" : "false"
        }
    }
}

extension SwiftServicesProtocol {
    private func queryOfReq(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }

    public func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []

        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: ArrayEncoding.brackets.encode(key: key), value: value)
            }
        } else if let value = value as? NSNumber {
            if value.isBool {
                components.append((escape(key), escape(BoolEncoding.numeric.encode(value: value.boolValue))))
            } else {
                components.append((escape(key), escape("\(value)")))
            }
        } else if let bool = value as? Bool {
            components.append((escape(key), escape(BoolEncoding.numeric.encode(value: bool))))
        } else {
            components.append((escape(key), escape("\(value)")))
        }

        return components
    }
    
    public func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        var escaped = ""

        if #available(iOS 8.3, *) {
            escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
        } else {
            let batchSize = 50
            var index = string.startIndex

            while index != string.endIndex {
                let startIndex = index
                let endIndex = string.index(index, offsetBy: batchSize, limitedBy: string.endIndex) ?? string.endIndex
                let range = startIndex..<endIndex

                let substring = string[range]

                escaped += substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? String(substring)

                index = endIndex
            }
        }
        return escaped
    }
}

enum HTTPMethod: String {
    case options = "OPTIONS"
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case trace = "TRACE"
    case connect = "CONNECT"
}

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

//MARK: AppServiceProtocol error types
enum SSError: Error {
    case undefined
    case notConnected
    case timeOut
}

//MARK: error types to handle
struct HTTPError: Error, Equatable {
    let statusCode: Int
    let data: Data
    
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.statusCode == rhs.statusCode }
    static func != (lhs: Self, rhs: Self) -> Bool { lhs.statusCode != rhs.statusCode }
    
    static var processing: Self { .init(statusCode: -1, data: Data()) }
    static var badRequest: Self { .init(statusCode: 400, data: Data()) }
    static var unauthorized: Self { .init(statusCode: 401, data: Data()) }
    static var paymentRequired: Self { .init(statusCode: 402, data: Data()) }
    static var forbidden: Self { .init(statusCode: 403, data: Data()) }
    static var notFound: Self { .init(statusCode: 404, data: Data()) }
    static var conflict: Self { .init(statusCode: 409, data: Data()) }
    static var internalServerError: Self { .init(statusCode: 500, data: Data()) }
}

struct HTTPNoReply: Codable { }
struct HTTPNoContent: Error { }

