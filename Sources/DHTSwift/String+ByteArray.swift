//
//  String+ByteArray.swift
//  DHTSwiftExecutable
//
//  Created by Lars Schwegmann on 12.06.19.
//

import Foundation

extension String {
    func toByteArray() -> [UInt8] {
        return Array(self.utf8)
    }
}

extension Array where Element == UInt8 {
    func toString() -> String? {
        return String(bytes: self, encoding: .utf8)
    }
}
