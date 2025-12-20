//
//  SwiftServices.swift
//  SwiftServices
//
//  Created by Kazim Ahmad on 20/12/2025.
//

import Combine
import Foundation

public class ObserverObject: ObservableObject {
    public var cancellables: Set<AnyCancellable> = []
    
    public func sync<O: ObservableObject>(with object: O) {
        object.objectWillChange
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in self?.objectWillChange.send() })
            .store(in: &cancellables)
    }
    
    public func observe<P: Publisher>(_ publisher: P,
                                      receiveValue: @escaping (P.Output) -> Void) where P.Failure == Never {
        publisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: receiveValue)
            .store(in: &cancellables)
    }
}
