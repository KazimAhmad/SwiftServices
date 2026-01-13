//
//  Endpoints.swift
//  SwiftServices
//
//  Created by Kazim Ahmad on 12/01/2026.
//

import Foundation
//MARK: the end points for app as enum to play around with the different version numbers and base urls
var version = "" // or some cases a version number as v1, v2 etc

public enum Endpoints {
    case character
    case location(id: String)
    
    var path: String {
        switch self {
        case .character:
            return baseURLString + version + "character"
        case .location(let id):
            return baseURLString + version + "location/" + id
        }
    }
}

//MARK: can define according to the environments
let baseURLString = "https://rickandmortyapi.com/api/"
