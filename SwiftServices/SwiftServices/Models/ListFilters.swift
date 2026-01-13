//
//  ListFilters.swift
//  SwiftServices
//
//  Created by Kazim Ahmad on 12/01/2026.
//

import Foundation

struct ListFilters {
    var searchText: String = ""
    var status: CharacterStatus?
    var gender: CharacterGender?
    var species: CharacterSpecies?
}

enum CharacterSpecies: String, CaseIterable {
    case human = "Human"
    case alien = "Alien"
}
