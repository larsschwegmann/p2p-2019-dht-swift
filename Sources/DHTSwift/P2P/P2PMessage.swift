//
//  P2PMessage.swift
//  DHTSwift
//
//  Created by Lars Schwegmann on 12.06.19.
//

import Foundation

// MARK: P2PStorageGet

struct P2PStorageGet: NetworkMessage, Equatable {
    static let messageTypeID: UInt16 = 1000

    let replicationIndex: UInt8
    let key: [UInt8] // 256 Bit

    var serializedBody: [UInt8] {
        var bytes = [UInt8]()

        // Replication
        var replicationIndexBigEndian = replicationIndex.bigEndian
        let replicationIndexBytes = withUnsafeBytes(of: &replicationIndexBigEndian, { $0 })
        bytes.append(contentsOf: replicationIndexBytes)
        // Reserved
        bytes.append(contentsOf: Array<UInt8>(repeating: 0x00, count: 3))
        // RawKey
        bytes.append(contentsOf: key)

        return bytes
    }

    public init(replicationIndex: UInt8, key: [UInt8]) {
        self.replicationIndex = replicationIndex
        self.key = key
    }

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 36 else {
            return nil
        }
        self.replicationIndex = serializedBodyBytes[0]
        self.key = Array(serializedBodyBytes[4...35])
    }
}

// MARK: P2PStoragePut

struct P2PStoragePut: NetworkMessage, Equatable {
    static var messageTypeID: UInt16 = 1001

    let ttl: UInt16
    let replicationIndex: UInt8
    let key: [UInt8] // 256 Bit
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
        bytes.append(contentsOf: key)
        // Value
        bytes.append(contentsOf: value)

        return bytes
    }

    public init(ttl: UInt16, replicationIndex: UInt8, key: [UInt8], value: [UInt8]) {
        self.ttl = ttl
        self.replicationIndex = replicationIndex
        self.key = key
        self.value = value
    }

    public init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count > 36 else {
            return nil
        }
        self.ttl = serializedBodyBytes[0...1].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
        self.replicationIndex = serializedBodyBytes[2]
        self.key = Array(serializedBodyBytes[4...35])
        self.value = Array(serializedBodyBytes[36...])
    }
}

// MARK: P2PStorageGetSuccess

struct P2PStorageGetSuccess: NetworkMessage, Equatable {
    static var messageTypeID: UInt16 = 1002

    let key: [UInt8]
    let value: [UInt8]

    var serializedBody: [UInt8] {
        var bytes = [UInt8]()

        // Key
        bytes.append(contentsOf: key)
        // Value
        bytes.append(contentsOf: value)

        return bytes
    }

    public init(key: [UInt8], value: [UInt8]) {
        self.key = key
        self.value = value
    }

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count > 32 else {
            return nil
        }
        self.key = Array(serializedBodyBytes[0...31])
        self.value = Array(serializedBodyBytes[32...])
    }
}

// MARK: P2PStoragePutSuccess

struct P2PStoragePutSuccess: NetworkMessage, Equatable {
    static var messageTypeID: UInt16 = 1003

    let key: [UInt8]

    var serializedBody: [UInt8] {
        return key
    }

    public init(key: [UInt8]) {
        self.key = key
    }

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 32 else {
            return nil
        }
        self.key = serializedBodyBytes
    }
}

// MARK: P2PStorageFailure

struct P2PStorageFailure: NetworkMessage, Equatable {
    static var messageTypeID: UInt16 = 1004

    let key: [UInt8]

    var serializedBody: [UInt8] {
        return key
    }

    public init(key: [UInt8]) {
        self.key = key
    }

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 32 else {
            return nil
        }
        self.key = serializedBodyBytes
    }

}

// MARK: P2PPeerFind

struct P2PPeerFind: NetworkMessage, Equatable {
    static let messageTypeID: UInt16 = 1050

    let key: [UInt8] // 256 Bit

    var serializedBody: [UInt8] {
        return self.key
    }

    public init(key: [UInt8]) {
        self.key = key
    }

    init?(serializedBodyBytes: [UInt8]) {
        self.key = serializedBodyBytes
    }


}

// MARK: P2PPeerFound

struct P2PPeerFound: NetworkMessage, Equatable {
    static let messageTypeID: UInt16 = 1051

    let key: [UInt8]    // 256 Bit
    let ipAddr: [UInt8] // 128 Bit IPv6 Addr
    let port: UInt16

    var serializedBody: [UInt8] {
        var bytes = [UInt8]()
        // Key
        bytes.append(contentsOf: key)
        // IP Address
        bytes.append(contentsOf: ipAddr)
        // Port
        var portBigEndian = port.bigEndian
        let portBytes = withUnsafeBytes(of: &portBigEndian, { $0 })
        bytes.append(contentsOf: portBytes)
        return bytes
    }

    public init(key: [UInt8], ipAddr: [UInt8], port: UInt16) {
        self.key = key
        self.ipAddr = ipAddr
        self.port = port
    }

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 50 else {
            return nil
        }
        self.key = Array(serializedBodyBytes[0...31])
        self.ipAddr = Array(serializedBodyBytes[32...47])
        self.port = serializedBodyBytes[48...].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
    }


}

// MARK: P2PPredecessorNotify

struct P2PPredecessorNotify: NetworkMessage, Equatable {
    static let messageTypeID: UInt16 = 1052

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

// MARK: P2PPRedecessorReply

struct P2PPredecessorReply: NetworkMessage, Equatable {
    static let messageTypeID: UInt16 = 1053

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
