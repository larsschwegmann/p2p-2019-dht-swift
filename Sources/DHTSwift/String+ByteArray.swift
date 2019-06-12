//
//  String+ByteArray.swift
//  DHTSwiftExecutable
//
//  Created by Lars Schwegmann on 12.06.19.
//

import Foundation

extension String {
    func toByteArray(cut: Int) -> [UInt8] {
        if self.utf8.count == cut {
            return Array(self.utf8)
        } else if self.utf8.count > cut {
            var bytes = [UInt8]()
            for (i, byte) in self.utf8.enumerated() {
                if i < cut {
                    bytes[i] = byte
                }
            }
            return bytes
        } else if self.utf8.count < cut {
            var bytes = Array(self.utf8)
            (0...(cut - self.utf8.count)).forEach { _ in
                bytes.append(0x00)
            }
            return bytes

        }
        return Array(self.utf8)
    }
}

extension Array where Element == UInt8 {
    func toString(size: Int) -> String? {
        guard self.count == size else {
            return nil
        }
        return String(bytes: self, encoding: .utf8)
    }
}
