//
//  RnMCharacter.swift
//  RickAndMorty
//
//  Created by Kazim Ahmad on 21/10/2025.
//

import Foundation
import SwiftUI

// MARK: - RnMCharacter
public struct RnMCharacter: Decodable {
    public let id: Int
    let name, species, type: String
    let status: CharacterStatus
    let gender: CharacterGender
    let origin, location: RnMLocation
    let image: String
    let episode: [String]
    let url: String
    let created: Date
}

enum CharacterStatus: String, Decodable, CaseIterable {
    case alive = "Alive"
    case dead = "Dead"
    case unknown = "unknown"
    
    var color: Color {
        switch self {
        case .alive:
            return .green
        case .dead:
            return .red
        default:
            return .gray
        }
    }
}

enum CharacterGender: String, Decodable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case genderless = "Genderless"
    case unknown = "unknown"
}

extension RnMCharacter: Identifiable, Hashable {
    public static func == (lhs: RnMCharacter, rhs: RnMCharacter) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public var identifier: String { String(self.id) }
}
