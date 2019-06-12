//
//  P2PMessage.swift
//  DHTSwift
//
//  Created by Lars Schwegmann on 12.06.19.
//

import Foundation

// MARK: P2PStorageGet

struct P2PStorageGet: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }

    
}

// MARK: P2PStoragePut

struct P2PStoragePut: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }


}

// MARK: P2PStorageGetSuccess

struct P2PStorageGetSuccess: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }


}

// MARK: P2PStoragePutSuccess

struct P2PStoragePutSuccess: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }


}

// MARK: P2PStorageFailure

struct P2PStorageFailure: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }


}

// MARK: P2PPeerFind

struct P2PPeerFind: NetworkMessage, Equatable {
    static let messageTypeID: UInt16 = 1050

    let key: [UInt8] // 256 Bit

    var serializedBody: [UInt8] {
        return self.key
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

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 50 else {
            return nil
        }
        self.key = Array(serializedBodyBytes[0...31])
        self.ipAddr = Array(serializedBodyBytes[32...47])
        self.port = serializedBodyBytes[48...].withUnsafeBytes({ $0.load(as: UInt16.self) })
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

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 18 else {
            return nil
        }
        self.ipAddr = Array(serializedBodyBytes[0...15])
        self.port = serializedBodyBytes[16...].withUnsafeBytes({ $0.load(as: UInt16.self) })
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

    init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 18 else {
            return nil
        }
        self.ipAddr = Array(serializedBodyBytes[0...15])
        self.port = serializedBodyBytes[16...].withUnsafeBytes({ $0.load(as: UInt16.self) })
    }
}
