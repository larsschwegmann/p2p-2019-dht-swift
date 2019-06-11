//
//  APIMessage.swift
//  dht-module
//
//  Created by Lars Schwegmann on 11.06.19.
//

import Foundation

// MARK: - API Message

protocol APIMessage {
    static var messageTypeID: UInt16 { get }
    var serializedBody: [UInt8] { get }
    init?(serializedBodyBytes: [UInt8])
}

extension APIMessage {
    func getBytes() -> [UInt8] {
        var bytes = [UInt8]()
        let messageBody = self.serializedBody
        let messageSize = messageBody.count + 4
        let messageTypeID = Self.messageTypeID

        // Size
        var messageSizeBigEndian = messageSize.bigEndian
        let messageSizeBytes = withUnsafeBytes(of: &messageSizeBigEndian, { $0 })
        bytes.append(contentsOf: messageSizeBytes)

        // Message Type ID
        var messageTypeIDBigEndian = messageTypeID.bigEndian
        let messageTypeIDBytes = withUnsafeBytes(of: &messageTypeIDBigEndian, { $0 })
        bytes.append(contentsOf: messageTypeIDBytes)

        // Body
        bytes.append(contentsOf: messageBody)

        return bytes
    }

    static func fromBytes(_ bytes: [UInt8]) -> APIMessage? {
        let messageTypeID = bytes[2...3].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
        let messageBody = Array(bytes[4...])
        switch messageTypeID {
        case DHTPut.messageTypeID:
            return DHTPut(serializedBodyBytes: messageBody)
        case DHTGet.messageTypeID:
            return DHTGet(serializedBodyBytes: messageBody)
        case DHTFailure.messageTypeID:
            return DHTFailure(serializedBodyBytes: messageBody)
        case DHTSuccess.messageTypeID:
            return DHTSuccess(serializedBodyBytes: messageBody)
        default:
            return nil
        }
    }
}

// MARK: - DHTPut

struct DHTPut: APIMessage {
    static let messageTypeID: UInt16 = 650

    let ttl: UInt16
    let replication: UInt8
    let reserved: UInt8
    let key: [UInt8] // 256 Bit
    let value: [UInt8]

    var serializedBody: [UInt8] {
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
        var reservedBigEndian = replicationBigEndian.bigEndian
        let reserverBytes = withUnsafeBytes(of: &reservedBigEndian, { $0 })
        bytes.append(contentsOf: reserverBytes)
        // Key
        bytes.append(contentsOf: key)
        // Value
        bytes.append(contentsOf: value)

        return bytes
    }

    init(ttl: UInt16, replication: UInt8, reserved: UInt8, key: [UInt8], value: [UInt8]) {
        self.ttl = ttl
        self.replication = replication
        self.reserved = reserved
        self.key = key
        self.value = value
    }

    init?(serializedBodyBytes: [UInt8]) {
        self.ttl = serializedBodyBytes[0...1].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
        self.replication = serializedBodyBytes[2]
        self.reserved = serializedBodyBytes[3]
        self.key = Array(serializedBodyBytes[4...36])
        self.value = Array(serializedBodyBytes[37...])
    }
}

// MARK: - DHTGet

struct DHTGet: APIMessage {
    static let messageTypeID: UInt16 = 651

    let key: [UInt8] // 256 Bit

    var serializedBody: [UInt8] {
        return key
    }

    init(key: [UInt8]) {
        self.key = key
    }

    init?(serializedBodyBytes: [UInt8]) {
        self.key = serializedBodyBytes
    }
}

// MARK: - DHTSuccess

struct DHTSuccess: APIMessage {
    static let messageTypeID: UInt16 = 652

    let key: [UInt8] // 256 Bit
    let value: [UInt8]

    var serializedBody: [UInt8] {
        var bytes = [UInt8]()

        // Key
        bytes.append(contentsOf: key)
        // Value
        bytes.append(contentsOf: value)

        return bytes
    }

    init(key: [UInt8], value: [UInt8]) {
        self.key = key
        self.value = value
    }

    init?(serializedBodyBytes: [UInt8]) {
        self.key = Array(serializedBodyBytes[0...31])
        self.value = Array(serializedBodyBytes[32...])
    }
}

// MARK: - DHTFailure

struct DHTFailure: APIMessage {
    static let messageTypeID: UInt16 = 653

    let key: [UInt8]

    var serializedBody: [UInt8] {
        return key
    }

    init(key: [UInt8]) {
        self.key = key
    }

    init?(serializedBodyBytes: [UInt8]) {
        self.key = serializedBodyBytes
    }
}
