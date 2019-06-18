import Foundation
import NIO
import CryptoSwift
import UInt256

enum Identifier {

    public struct Key {
        let rawKey: UInt256
        let replicationIndex: UInt8
    }

    case socketAddress(address: SocketAddress)
    case key(Key)
    case existingHash(UInt256)

    var hashValue: UInt256? {
        switch self {
        case .socketAddress(address: let addr):
            switch addr {
            case .v4(let v4):
                var uint32 = v4.address.sin_addr.s_addr
                return UInt256(bytes: Array(withUnsafeBytes(of: &uint32, { $0 })).sha256())
            case .v6(let v6):
                var tmp = v6.address.sin6_addr.__u6_addr.__u6_addr8
                let bytes = [UInt8](UnsafeBufferPointer(start: &tmp.0, count: MemoryLayout.size(ofValue: tmp)))
                return UInt256(bytes: bytes)
            default:
                return nil
            }
        case .key(let key):
            let keyBytes = key.rawKey.getBytes() + [key.replicationIndex]
            return UInt256(bytes:keyBytes.sha256())
        case .existingHash(let hash):
            return hash
        }
    }

    func isBetween(lhs: Identifier, rhs: Identifier) -> Bool {
        let (diff1, _) = rhs.hashValue!.subtractingReportingOverflow(self.hashValue!)
        let (diff2, _) = lhs.hashValue!.subtractingReportingOverflow(lhs.hashValue!)
        return diff1 < diff2
    }
}

extension Identifier: Comparable {
    static func < (lhs: Identifier, rhs: Identifier) -> Bool {
        return lhs.hashValue! < rhs.hashValue!
    }

    static func == (lhs: Identifier, rhs: Identifier) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension Identifier {
    public static func +(_ lhs: Identifier, _ rhs: Identifier) -> Identifier {
        let (retVal, _) = lhs.hashValue!.addingReportingOverflow(rhs.hashValue!)
        return Identifier.existingHash(retVal)
    }
}
