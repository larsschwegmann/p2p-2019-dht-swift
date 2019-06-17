import Foundation
import NIO
import UInt256

extension SocketAddress {

    init(ipv6Bytes: [UInt8], port: UInt16) throws {
        let bytes = (ipv6Bytes[0], ipv6Bytes[1], ipv6Bytes[2], ipv6Bytes[3], ipv6Bytes[4], ipv6Bytes[5], ipv6Bytes[6], ipv6Bytes[7],
                     ipv6Bytes[8], ipv6Bytes[9], ipv6Bytes[10], ipv6Bytes[11], ipv6Bytes[12], ipv6Bytes[13], ipv6Bytes[14], ipv6Bytes[15])
        let ipv6Addr = in6_addr(__u6_addr: in6_addr.__Unnamed_union___u6_addr(__u6_addr8: bytes))
        var addr = sockaddr_in6()
        addr.sin6_family = sa_family_t(AF_INET6)
        addr.sin6_port = in_port_t(port).bigEndian
        addr.sin6_flowinfo = 0
        addr.sin6_addr = ipv6Addr
        addr.sin6_scope_id = 0
        self.init(addr, host: "")
    }

    /**
     Returns the the bytes of the SocketAddress regarding to the doku of bene
    */
    func getIPv6Bytes() -> [UInt8]? {
        switch self {
        case .v4(let v4):
            var uint32 = v4.address.sin_addr.s_addr
            return Array<UInt8>(repeating: 0x00, count: 10) + [0xff, 0xff] + Array(withUnsafeBytes(of: &uint32, { $0 }))
        case .v6(let v6):
            var tmp = v6.address.sin6_addr.__u6_addr.__u6_addr8
            return [UInt8](UnsafeBufferPointer(start: &tmp.0, count: MemoryLayout.size(ofValue: tmp)))
        default:
            return nil
        }
    }
}
