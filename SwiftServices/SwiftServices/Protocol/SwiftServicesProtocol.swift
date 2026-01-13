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
