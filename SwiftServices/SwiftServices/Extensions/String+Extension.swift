//
//  SwiftServices.swift
//  SwiftServices
//
//  Created by Kazim Ahmad on 20/12/2025.
//

import Foundation

extension String {
    var addingPercentEncodingForURLFormValue: String? {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._* ")
        return addingPercentEncoding(withAllowedCharacters: allowedCharacters)?.replacingOccurrences(of: " ", with: "+")
    }
}
