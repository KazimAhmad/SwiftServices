//
//  SwiftServices.swift
//  SwiftServices
//
//  Created by Kazim Ahmad on 20/12/2025.
//

import Foundation

extension JSONDecoder.DateDecodingStrategy {
    static let customDate = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)
        if let formattedFullDate = Formatter.iso8601FormatWithTandZ.date(from: string) {
            return formattedFullDate
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
    }
}

class DateConverter {
    static let dateFormatWithTandZ = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
}

extension Formatter {
    static let iso8601FormatWithTandZ: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = DateConverter.dateFormatWithTandZ
        return formatter
    }()
}
