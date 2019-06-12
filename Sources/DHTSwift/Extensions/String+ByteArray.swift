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
            (0...(cut - self.utf8.count - 1)).forEach { _ in
                bytes.append(0x00)
            }
            return bytes

        }
        return Array(self.utf8)
    }

    func split(by length: Int) -> [String] {
        var startIndex = self.startIndex
        var results = [Substring]()

        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            results.append(self[startIndex..<endIndex])
            startIndex = endIndex
        }

        return results.map { String($0) }
    }
}

extension Array where Element == UInt8 {
    func toString(size: Int) -> String? {
        guard self.count == size else {
            return nil
        }
        return String(bytes: self, encoding: .utf8)
    }

    init?(ipv4String: String) {
        let components = ipv4String.split(separator: ".")
        guard components.count == 4 else {
            return nil
        }
        let ipv4 = components.compactMap({ return UInt8($0) })
        var bytes = Array<UInt8>(repeating: 0x00, count: 10)
        bytes.append(contentsOf: Array<UInt8>(repeating: 0xff, count: 2))
        bytes.append(contentsOf: ipv4)
        self.init(bytes)
    }

    /// Note: This onlony works with fully written out IPv6 adressess, not with something like ::1
    init?(ipv6String: String) {
        let sanitized = ipv6String.split(separator: ":").joined()
        guard sanitized.count == 32 else {
            return nil
        }
        let ipv6 = sanitized.split(by: 2).compactMap({ UInt8(String($0), radix: 16) })
        self.init(ipv6)
    }
}
