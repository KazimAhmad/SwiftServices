//
//  CharacterData.swift
//  RickAndMorty
//
//  Created by Kazim Ahmad on 21/10/2025.
//

import Foundation

// MARK: - CharacterData
struct CharacterData: Decodable {
    var info: CharacterInfo
    var characters: [RnMCharacter]
    
    enum CodingKeys: String, CodingKey {
        case info
        case characters = "results"
    }
    //MARK: now using the object and async await i am using the object to play around with the CRUD from the API
    //so then i can use the object itself to access the method wherever i want in the app like:

    /* and the same way to all of the operations on the object like
    func update() async throws {}
    func delete() async throws {}
    func create() async throws -> Self {}
     
     and then in the app where i have an object i can use like:
     let character: RnMCharacter?
     
     func charFromAPI() {
        character = RnMCharacter()
     }
     
     func updateCharacter() {
        character.valueToUpdate = updatedValue
        character.update()
     }
    */
    
    static func get(for page: Int = 1,
                    filters: ListFilters) async throws -> Self {
        var query: [String: Any] = ["page": page]
        if filters.searchText != "" {
            query["name"] = filters.searchText
        }
        if filters.species != nil {
            query["species"] = filters.species
        }
        if filters.gender != nil {
            query["gender"] = filters.gender
        }
        if filters.status != nil {
            query["status"] = filters.status
        }
        return try await SwiftServices.shared.request(Endpoints.character.path,
                                                 query: query)
    }
}
