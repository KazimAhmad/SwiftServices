//
//  SwiftServicesTests.swift
//  SwiftServicesTests
//
//  Created by Kazim Ahmad on 20/12/2025.
//

import XCTest
@testable import SwiftServices

final class SwiftServicesTests: XCTestCase {

    var sut = SwiftServices.shared

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testLocations() async throws {
        let expectation = expectation(description: "Should fetch 1 location")
        let idForLocation: Int = 1
        let location = try await CharacterLocation.get(for: String(idForLocation))
        XCTAssertTrue(location.id == idForLocation)
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testLocationsFromServices() async throws {
        let idForLocation: Int = 1
        let location = try await sut.getLocations(for: String(idForLocation))
        XCTAssertTrue(location.id == idForLocation)
    }
    
    func testLocationsFromServiceWithTime() async {
        let startTime = Date()
        Task {
            let location = try await sut.getLocations(for: String(1))
            let elapsedTime = Date().timeIntervalSince(startTime)
            XCTAssertEqual(location.id, 1, "Should fetch 1 location")
            XCTAssertLessThan(elapsedTime, 0.5)
        }
    }    
}
