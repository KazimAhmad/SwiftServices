//
//  SwiftServices+Requests.swift
//  SwiftServices
//
//  Created by Kazim Ahmad on 12/01/2026.
//
import Combine
import Foundation

extension SwiftServices {
    func getLocations(for id: String) async throws -> CharacterLocation {
        return try await request(Endpoints.location(id: id).path)
    }
}
