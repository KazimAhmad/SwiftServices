//
//  HTTPError.swift
//  SwiftServices
//
//  Created by Kazim Ahmad on 23/12/2025.
//

import Foundation

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
