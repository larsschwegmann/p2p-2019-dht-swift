import UInt256
import Foundation

extension UInt256 {
    /// Given a 32 byte Array, constructs a UInt256
    init(bytes: [UInt8]) {
        var words = [UInt64]()
        for i in 0..<(bytes.count / 8) {
            let k = i * 8
            let uint64 = bytes[k...(k + 7)].withUnsafeBytes({ $0.load(as: UInt64.self) })
            words.append(uint64)
        }
        self.init(words.reversed())
    }

    /// Returns a byte array of the instance
    func getBytes() -> [UInt8] {
        let words = self.words
        var bytes = [UInt8]()
        for word in words {
            var cpy = UInt64(word)
            let byte = withUnsafeBytes(of: &cpy, { $0 })
            bytes.append(contentsOf: byte)
        }
        return bytes
    }

    func isBetween(lhs: UInt256, rhs: UInt256) -> Bool {
        let (diff1, _) = rhs.subtractingReportingOverflow(self)
        let (diff2, _) = rhs.subtractingReportingOverflow(lhs)
        return diff1 < diff2
    }

    func isBetweenEnd(lhs: UInt256, rhs: UInt256) -> Bool {
        return self == rhs || self.isBetween(lhs: lhs, rhs: rhs)
    }
}
