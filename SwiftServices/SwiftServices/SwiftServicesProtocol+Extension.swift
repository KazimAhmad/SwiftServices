//
//  SwiftServicesProtocol+Extension.swift
//  SwiftServices
//
//  Created by Kazim Ahmad on 23/12/2025.
//

import Foundation

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
