import Foundation
import NIO
import UInt256

extension SocketAddress {

    init(ipv6Bytes: [UInt8], port: UInt16) throws {
        let bytes = (ipv6Bytes[0], ipv6Bytes[1], ipv6Bytes[2], ipv6Bytes[3], ipv6Bytes[4], ipv6Bytes[5], ipv6Bytes[6], ipv6Bytes[7],
                     ipv6Bytes[8], ipv6Bytes[9], ipv6Bytes[10], ipv6Bytes[11], ipv6Bytes[12], ipv6Bytes[13], ipv6Bytes[14], ipv6Bytes[15])
        if Array(ipv6Bytes[0...9]) == Array<UInt8>(repeating: 0, count: 10) &&
            Array(ipv6Bytes[10...11]) == Array<UInt8>(repeating: 255, count: 2) {
            // IPv4
            let ipv4Addr = in_addr(s_addr: ipv6Bytes[12...15].withUnsafeBytes({ $0.load(as: UInt32.self) }))
            var addr = sockaddr_in()
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = port.byteSwapped
            addr.sin_addr = ipv4Addr
            self.init(addr, host: "")
        } else {
            // IPv6
            #if os(Linux)
            let ipv6Addr = in6_addr(__in6_u: in6_addr.__Unnamed_union___in6_u(__u6_addr8: bytes))
            #else
            let ipv6Addr = in6_addr(__u6_addr: in6_addr.__Unnamed_union___u6_addr(__u6_addr8: bytes))
            #endif
            var addr = sockaddr_in6()
            addr.sin6_family = sa_family_t(AF_INET6)
            addr.sin6_port = in_port_t(port).bigEndian
            addr.sin6_flowinfo = 0
            addr.sin6_addr = ipv6Addr
            addr.sin6_scope_id = 0
            self.init(addr, host: "")
        }
    }


    init(ipv6BytesIncludingPort: [UInt8]) throws {
        let bytes = (ipv6BytesIncludingPort[0],
                     ipv6BytesIncludingPort[1],
                     ipv6BytesIncludingPort[2],
                     ipv6BytesIncludingPort[3],
                     ipv6BytesIncludingPort[4],
                     ipv6BytesIncludingPort[5],
                     ipv6BytesIncludingPort[6],
                     ipv6BytesIncludingPort[7],
                     ipv6BytesIncludingPort[8],
                     ipv6BytesIncludingPort[9],
                     ipv6BytesIncludingPort[10],
                     ipv6BytesIncludingPort[11],
                     ipv6BytesIncludingPort[12],
                     ipv6BytesIncludingPort[13],
                     ipv6BytesIncludingPort[14],
                     ipv6BytesIncludingPort[15])
        if Array(ipv6BytesIncludingPort[0...9]) == Array<UInt8>(repeating: 0, count: 10)
            && Array(ipv6BytesIncludingPort[10...11]) == Array<UInt8>(repeating: 255, count: 2) {
            // IPv4
            let ipv4Addr = in_addr(s_addr: ipv6BytesIncludingPort[12...15].withUnsafeBytes({ $0.load(as: UInt32.self) }))
            var addr = sockaddr_in()
            addr.sin_family = sa_family_t(AF_INET)
            let port = ipv6BytesIncludingPort[16...17].withUnsafeBytes({ $0.load(as: UInt16.self) })
            addr.sin_port = port.byteSwapped
            addr.sin_addr = ipv4Addr
            self.init(addr, host: "")
        } else {
            // IPv6
            #if os(Linux)
            let ipv6Addr = in6_addr(__in6_u: in6_addr.__Unnamed_union___in6_u(__u6_addr8: bytes))
            #else
            let ipv6Addr = in6_addr(__u6_addr: in6_addr.__Unnamed_union___u6_addr(__u6_addr8: bytes))
            #endif
            var addr = sockaddr_in6()
            addr.sin6_family = sa_family_t(AF_INET6)
            let port = ipv6BytesIncludingPort[16...17].withUnsafeBytes({ $0.load(as: UInt16.self) })
            addr.sin6_port = in_port_t(port).bigEndian
            addr.sin6_flowinfo = 0
            addr.sin6_addr = ipv6Addr
            addr.sin6_scope_id = 0
            self.init(addr, host: "")
        }
    }


    /// Returns the the bytes of the SocketAddress regarding to the doku of bene
    func getIPv6Bytes() -> [UInt8]? {
        switch self {
        case .v4(let v4):
            var uint32 = v4.address.sin_addr.s_addr
            return Array<UInt8>(repeating: 0x00, count: 10) + [0xff, 0xff] + Array(withUnsafeBytes(of: &uint32, { $0 }))
        case .v6(let v6):
            #if os(Linux)
            var tmp = v6.address.sin6_addr.__in6_u.__u6_addr8
            #else
            var tmp = v6.address.sin6_addr.__u6_addr.__u6_addr8
            #endif
            return [UInt8](UnsafeBufferPointer(start: &tmp.0, count: MemoryLayout.size(ofValue: tmp)))
        default:
            return nil
        }
    }

    func getIPv6BytesIncludingPort() -> [UInt8]? {
        switch self {
        case .v4(let v4):
            var uint32 = v4.address.sin_addr.s_addr
            var port = v4.address.sin_port
            return Array<UInt8>(repeating: 0x00, count: 10)
                + [0xff, 0xff]
                + Array(withUnsafeBytes(of: &uint32, { $0 }))
                + Array(withUnsafeBytes(of: &port, { $0 }))
        case .v6(let v6):
            #if os(Linux)
            var tmp = v6.address.sin6_addr.__in6_u.__u6_addr8
            var port = v6.address.sin6_port.bigEndian
            #else
            var tmp = v6.address.sin6_addr.__u6_addr.__u6_addr8
            var port = v6.address.sin6_port.bigEndian
            #endif
            return [UInt8](UnsafeBufferPointer(start: &tmp.0, count: MemoryLayout.size(ofValue: tmp))) + Array(withUnsafeBytes(of: &port, { $0 }))
        default:
            return nil
        }
    }
}
