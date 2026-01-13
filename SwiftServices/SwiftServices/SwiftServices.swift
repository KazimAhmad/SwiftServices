//
//  SwiftServices.swift
//  SwiftServices
//
//  Created by Kazim Ahmad on 20/12/2025.
//

import Foundation

class SwiftServices: SwiftServicesProtocol {
    static let shared = SwiftServices()
    
    //start the session with configurations
    var session: URLSession = URLSession.defaultJSON
    
    let encoder: JSONEncoder = {
        let coder = JSONEncoder()
        return coder
    }()
    let decoder: JSONDecoder = {
        let coder = JSONDecoder()
        //when using dates in the app, can use a custom type here to handle all the cases
        coder.dateDecodingStrategy = .customDate
        return coder
    }()
    let errorType: (Codable & Error).Type? = nil
    
    var isRequestingAccess: Bool = false

    //MARK: this is to use when app creats session of a user
    /*
     and then change the main root view in the app view
     in this case i am using this example to go from onboarding to the list view
     we can use navigtion path to go to the list view but i wanted to include an example
     to change the root view of the app, i am using the navigation stack for the list view
     */
    @Published var isAuthSkipped: Bool? = nil

    init() {

    }
    
    func willSendRequest(_ request: inout URLRequest) async throws {
        //MARK: -Add the Authorization token to headers (if required) like this:
        /*
         request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")
         */
        //MARK: the api key should be saved in the server side for protection
    }
        
    func shouldRetry(withError error: Error) async -> Bool {
        if let error = error as? HTTPError {
            if error.statusCode == 401 {
                //MARK: -in case the token was expired; refresh the token, save it and retry the request
                return true
            }
        }
        return false
    }
}
