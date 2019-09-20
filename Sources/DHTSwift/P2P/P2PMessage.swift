import Foundation
import UInt256
import NIO

// MARK: - P2PStorageGet

struct P2PStorageGet: NetworkMessage, Equatable {
    static let messageTypeID: NetworkMessageTypeID = .P2PStorageGetID

    let replicationIndex: UInt8
    let key: UInt256

    var serializedBody: [UInt8] {
        var bytes = [UInt8]()

        // Replication
        var replicationIndexBigEndian = replicationIndex.bigEndian
        let replicationIndexBytes = withUnsafeBytes(of: &replicationIndexBigEndian, { $0 })
        bytes.append(contentsOf: replicationIndexBytes)
        // Reserved
        bytes.append(contentsOf: Array<UInt8>(repeating: 0x00, count: 3))
        // RawKey
        bytes.append(contentsOf: key.getBytes())

        return bytes
    }

    public init(replicationIndex: UInt8, key: UInt256) {
        self.replicationIndex = replicationIndex
        self.key = key
    }

    public init(replicationIndex: UInt8, key: [UInt8]) {
        self.replicationIndex = replicationIndex
        self.key = UInt256(bytes: key)
    }

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 36 else {
            return nil
        }
        self.replicationIndex = serializedBodyBytes[0]
        self.key = UInt256(bytes: Array(serializedBodyBytes[4...35]))
    }
}

// MARK: - P2PStoragePut

struct P2PStoragePut: NetworkMessage, Equatable {
    static var messageTypeID: NetworkMessageTypeID = .P2PStoragePutID

    let ttl: UInt16
    let replicationIndex: UInt8
    let key: UInt256
    let value: [UInt8]

    var serializedBody: [UInt8] {
        var bytes = [UInt8]()

        // TTL
        var ttlBigEndian = ttl.bigEndian
        let ttlBytes = withUnsafeBytes(of: &ttlBigEndian, { $0 })
        bytes.append(contentsOf: ttlBytes)

        // Replication
        var replicationIndexBigEndian = replicationIndex.bigEndian
        let replicationIndexBytes = withUnsafeBytes(of: &replicationIndexBigEndian, { $0 })
        bytes.append(contentsOf: replicationIndexBytes)

        // Reserved
        bytes.append(0x00)
        // RawKey
        bytes.append(contentsOf: key.getBytes())
        // Value
        bytes.append(contentsOf: value)

        return bytes
    }

    public init(ttl: UInt16, replicationIndex: UInt8, key: UInt256, value: [UInt8]) {
        self.ttl = ttl
        self.replicationIndex = replicationIndex
        self.key = key
        self.value = value
    }

    public init(ttl: UInt16, replicationIndex: UInt8, key: [UInt8], value: [UInt8]) {
        self.ttl = ttl
        self.replicationIndex = replicationIndex
        self.key = UInt256(bytes: key)
        self.value = value
    }

    public init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count > 36 else {
            return nil
        }
        self.ttl = serializedBodyBytes[0...1].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
        self.replicationIndex = serializedBodyBytes[2]
        self.key = UInt256(bytes: Array(serializedBodyBytes[4...35]))
        self.value = Array(serializedBodyBytes[36...])
    }
}

// MARK: - P2PStorageGetSuccess

struct P2PStorageGetSuccess: NetworkMessage, Equatable {
    static var messageTypeID: NetworkMessageTypeID = .P2PStorageGetSuccessID

    let key: UInt256
    let value: [UInt8]

    var serializedBody: [UInt8] {
        var bytes = [UInt8]()

        // Key
        bytes.append(contentsOf: key.getBytes())
        // Value
        bytes.append(contentsOf: value)

        return bytes
    }

    public init(key: UInt256, value: [UInt8]) {
        self.key = key
        self.value = value
    }

    public init(key: [UInt8], value: [UInt8]) {
        self.key = UInt256(bytes: key)
        self.value = value
    }

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count > 32 else {
            return nil
        }
        self.key = UInt256(bytes: Array(serializedBodyBytes[0...31]))
        self.value = Array(serializedBodyBytes[32...])
    }
}

// MARK: - P2PStoragePutSuccess

struct P2PStoragePutSuccess: NetworkMessage, Equatable {
    static var messageTypeID: NetworkMessageTypeID = .P2PStoragePutSuccessID

    let key: UInt256

    var serializedBody: [UInt8] {
        return key.getBytes()
    }

    public init(key: UInt256) {
        self.key = key
    }

    public init(key: [UInt8]) {
        self.key = UInt256(bytes: key)
    }

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 32 else {
            return nil
        }
        self.key = UInt256(bytes: serializedBodyBytes)
    }
}

// MARK: - P2PStorageFailure

struct P2PStorageFailure: NetworkMessage, Equatable {
    static var messageTypeID: NetworkMessageTypeID = .P2PStorageFailureID

    let key: UInt256

    var serializedBody: [UInt8] {
        return key.getBytes()
    }

    public init(key: UInt256) {
        self.key = key
    }

    public init(key: [UInt8]) {
        self.key = UInt256(bytes: key)
    }

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 32 else {
            return nil
        }
        self.key = UInt256(bytes: serializedBodyBytes)
    }

}

// MARK: - P2PPeerFind

struct P2PPeerFind: NetworkMessage, Equatable {
    static let messageTypeID: NetworkMessageTypeID = .P2PPeerFindID

    let key: UInt256

    var serializedBody: [UInt8] {
        return self.key.getBytes()
    }

    public init(key: UInt256) {
        self.key = key
    }

    public init(key: [UInt8]) {
        self.key = UInt256(bytes: key)
    }

    init?(serializedBodyBytes: [UInt8]) {
        self.key = UInt256(bytes: serializedBodyBytes)
    }
}

// MARK: - P2PPeerFound

struct P2PPeerFound: NetworkMessage, Equatable {
    static let messageTypeID: NetworkMessageTypeID = .P2PPeerFoundID

    let key: UInt256
    let ipAddr: [UInt8] // 128 Bit IPv6 Addr
    let port: UInt16

    var serializedBody: [UInt8] {
        var bytes = [UInt8]()
        // Key
        bytes.append(contentsOf: key.getBytes())
        // IP Address
        bytes.append(contentsOf: ipAddr)
        // Port
        var portBigEndian = port.bigEndian
        let portBytes = withUnsafeBytes(of: &portBigEndian, { $0 })
        bytes.append(contentsOf: portBytes)
        return bytes
    }

    public init(key: UInt256, ipAddr: [UInt8], port: UInt16) {
        self.key = key
        self.ipAddr = ipAddr
        self.port = port
    }

    public init(key: [UInt8], ipAddr: [UInt8], port: UInt16) {
        self.key = UInt256(bytes: key)
        self.ipAddr = ipAddr
        self.port = port
    }

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 50 else {
            return nil
        }
        self.key = UInt256(bytes: Array(serializedBodyBytes[0...31]))
        self.ipAddr = Array(serializedBodyBytes[32...47])
        self.port = serializedBodyBytes[48...].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
    }
}

// MARK: - P2PPredecessorNotify

struct P2PPredecessorNotify: NetworkMessage, Equatable {
    static let messageTypeID: NetworkMessageTypeID = .P2PPredecessorNotifyID

    let ipAddr: [UInt8] // 128 Bit IPv6 Address
    let port: UInt16

    var serializedBody: [UInt8] {
        var bytes = [UInt8]()
        // IP Address
        bytes.append(contentsOf: ipAddr)
        // Port
        var portBigEndian = port.bigEndian
        let portBytes = withUnsafeBytes(of: &portBigEndian, { $0 })
        bytes.append(contentsOf: portBytes)
        return bytes
    }

    init(ipAddr: [UInt8], port: UInt16) {
        self.ipAddr = ipAddr
        self.port = port
    }

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 18 else {
            return nil
        }
        self.ipAddr = Array(serializedBodyBytes[0...15])
        self.port = serializedBodyBytes[16...].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
    }


}

// MARK: - P2PPRedecessorReply

struct P2PPredecessorReply: NetworkMessage, Equatable {
    static let messageTypeID: NetworkMessageTypeID = .P2PPredecessorReplyID

    let ipAddr: [UInt8] // 128 Bit IPv6 Address
    let port: UInt16

    var serializedBody: [UInt8] {
        var bytes = [UInt8]()
        // IP Address
        bytes.append(contentsOf: ipAddr)
        // Port
        var portBigEndian = port.bigEndian
        let portBytes = withUnsafeBytes(of: &portBigEndian, { $0 })
        bytes.append(contentsOf: portBytes)
        return bytes
    }

    init(ipAddr: [UInt8], port: UInt16) {
        self.ipAddr = ipAddr
        self.port = port
    }

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 18 else {
            return nil
        }
        self.ipAddr = Array(serializedBodyBytes[0...15])
        self.port = serializedBodyBytes[16...].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
    }
}

// MARK: - P2PSuccessorRequest

struct P2PSuccessorRequest: NetworkMessage {
    static let messageTypeID: NetworkMessageTypeID = .P2PSuccessorRequestID

    let serializedBody: [UInt8] = []

    init?(serializedBodyBytes: [UInt8]) { }
}

// MARK: - P2PSuccessorReply

struct P2PSuccessorReply: NetworkMessage {
    static let messageTypeID: NetworkMessageTypeID = .P2PSuccessorReplyID

    let successors: [SocketAddress]

    var serializedBody: [UInt8] {
        return successors.flatMap { $0.getIPv6BytesIncludingPort() ?? [] }
    }

    init(successors: [SocketAddress]) {
        self.successors = successors
    }

    init?(serializedBodyBytes: [UInt8]) {
        var successors = [SocketAddress]()
        for addrPos in stride(from: 0, to: serializedBodyBytes.count, by: 8) {
            let addrBytes = Array(serializedBodyBytes[addrPos...addrPos+7])
            guard let addr = try? SocketAddress(ipv6BytesIncludingPort: addrBytes) else {
                continue
            }
            successors.append(addr)
        }
        self.successors = successors
    }
}
