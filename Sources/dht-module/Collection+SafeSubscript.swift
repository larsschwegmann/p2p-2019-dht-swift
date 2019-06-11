//
//  Collection+SafeSubscript.swift
//  dht-module
//
//  Created by Lars Schwegmann on 11.06.19.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
