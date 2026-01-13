//
//  RnMLocation.swift
//  RickAndMorty
//
//  Created by Kazim Ahmad on 21/10/2025.
//

import Foundation

// MARK: - Location
struct RnMLocation: Decodable {
    let name: String
    let url: String
    
    var id = UUID().uuidString
    
    enum CodingKeys: String, CodingKey {
        case name
        case url
    }
    
    init(name: String, url: String) {
        self.name = name
        self.url = url
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.url = try container.decode(String.self, forKey: .url)
        self.id = UUID().uuidString
    }
}

// MARK: - CharacterLocation
struct CharacterLocation: Codable {
    let id: Int
    let name, type, dimension: String
    let residents: [String]
    let url: String
    let created: Date
    
    static func get(for id: String) async throws -> Self {
        return try await SwiftServices.shared.request(Endpoints.location(id: id).path)
    }
}

extension RnMLocation: Identifiable, Hashable {
    var identifier: String { name }
    public static func == (lhs: RnMLocation, rhs: RnMLocation) -> Bool {
        return lhs.id == rhs.id
    }
}
