//
//  APIMessage.swift
//  dht-module
//
//  Created by Lars Schwegmann on 11.06.19.
//

import Foundation

// MARK: - DHTPut

public struct DHTPut: NetworkMessage, Equatable {
    public static let messageTypeID: UInt16 = 650

    let ttl: UInt16
    let replication: UInt8
    let key: [UInt8] // 256 Bit
    let value: [UInt8]

    public var serializedBody: [UInt8] {
        var bytes = [UInt8]()

        // TTL
        var ttlBigEndian = ttl.bigEndian
        let ttlBytes = withUnsafeBytes(of: &ttlBigEndian) { $0 }
        bytes.append(contentsOf: ttlBytes)
        // Replication
        var replicationBigEndian = replication.bigEndian
        let replicationBytes = withUnsafeBytes(of: &replicationBigEndian, { $0 })
        bytes.append(contentsOf: replicationBytes)
        // Reserved
        bytes.append(0x00)
        // Key
        bytes.append(contentsOf: key)
        // Value
        bytes.append(contentsOf: value)

        return bytes
    }

    public init(ttl: UInt16, replication: UInt8, key: [UInt8], value: [UInt8]) {
        self.ttl = ttl
        self.replication = replication
        self.key = key
        self.value = value
    }

    public init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count > 36 else {
            return nil
        }
        self.ttl = serializedBodyBytes[0...1].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
        self.replication = serializedBodyBytes[2]
        self.key = Array(serializedBodyBytes[4...35])
        self.value = Array(serializedBodyBytes[36...])
    }
}

// MARK: - DHTGet

public struct DHTGet: NetworkMessage, Equatable {
    public static let messageTypeID: UInt16 = 651

    let key: [UInt8] // 256 Bit

    public var serializedBody: [UInt8] {
        return key
    }

    public init(key: [UInt8]) {
        self.key = key
    }

    public init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 32 else {
            return nil
        }
        self.key = serializedBodyBytes
    }
}

// MARK: - DHTSuccess

public struct DHTSuccess: NetworkMessage, Equatable {
    public static let messageTypeID: UInt16 = 652

    let key: [UInt8] // 256 Bit
    let value: [UInt8]

    public var serializedBody: [UInt8] {
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

    public init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count > 32 else {
            return nil
        }
        self.key = Array(serializedBodyBytes[0...31])
        self.value = Array(serializedBodyBytes[32...])
    }
}

// MARK: - DHTFailure

public struct DHTFailure: NetworkMessage, Equatable {
    public static let messageTypeID: UInt16 = 653

    let key: [UInt8]

    public var serializedBody: [UInt8] {
        return key
    }

    public init(key: [UInt8]) {
        self.key = key
    }

    public init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count == 32 else {
            return nil
        }
        self.key = serializedBodyBytes
    }
}