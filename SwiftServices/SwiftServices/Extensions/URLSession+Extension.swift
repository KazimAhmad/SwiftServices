//
//  SwiftServices.swift
//  SwiftServices
//
//  Created by Kazim Ahmad on 20/12/2025.
//

import Foundation

extension URLSession {
    public static var defaultJSON: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 90
        configuration.timeoutIntervalForResource = 90
        configuration.httpAdditionalHeaders = ["Content-Type": "application/json",
                                               "Accept": "application/json"]
        configuration.urlCache = URLCache(memoryCapacity: 10485760,
                                          diskCapacity: 104857600)
        return URLSession(configuration: configuration)
    }
}
