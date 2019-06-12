//
//  APIMessage.swift
//  dht-module
//
//  Created by Lars Schwegmann on 11.06.19.
//

import Foundation

// MARK: - API Message

/// APIMessage protocol for use with the APIServer and APIClient
public protocol APIMessage {
    static var messageTypeID: UInt16 { get }
    var serializedBody: [UInt8] { get }
    init?(serializedBodyBytes: [UInt8])
}

public extension APIMessage {

    /**
     Serializes an entire APIMessage including the message header with size and message
    **/
    func getBytes() -> [UInt8] {
        var bytes = [UInt8]()
        let messageBody = self.serializedBody
        let messageSize = UInt16(messageBody.count + 4)
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

    /**
     Tries to create an APIMessage object from a given byte array
    **/
    static func fromBytes(_ bytes: [UInt8]) -> Self? {
        guard bytes.count > 4 else {
            // Message Header is missing
            return nil
        }
        let messageTypeID = bytes[2...3].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
        guard messageTypeID == Self.messageTypeID else {
            return nil
        }

        let messageBody = Array(bytes[4...])
        return Self(serializedBodyBytes: messageBody)
    }
}

// MARK: - DHTPut

public struct DHTPut: APIMessage, Equatable {
    public static let messageTypeID: UInt16 = 650

    let ttl: UInt16
    let replication: UInt8
    let reserved: UInt8
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
        var reservedBigEndian = reserved.bigEndian
        let reserverBytes = withUnsafeBytes(of: &reservedBigEndian, { $0 })
        bytes.append(contentsOf: reserverBytes)
        // Key
        bytes.append(contentsOf: key)
        // Value
        bytes.append(contentsOf: value)

        return bytes
    }

    public init(ttl: UInt16, replication: UInt8, reserved: UInt8, key: [UInt8], value: [UInt8]) {
        self.ttl = ttl
        self.replication = replication
        self.reserved = reserved
        self.key = key
        self.value = value
    }

    public init?(serializedBodyBytes: [UInt8]) {
        guard serializedBodyBytes.count > 36 else {
            return nil
        }
        self.ttl = serializedBodyBytes[0...1].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
        self.replication = serializedBodyBytes[2]
        self.reserved = serializedBodyBytes[3]
        self.key = Array(serializedBodyBytes[4...35])
        self.value = Array(serializedBodyBytes[36...])
    }
}

// MARK: - DHTGet

public struct DHTGet: APIMessage, Equatable {
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

public struct DHTSuccess: APIMessage, Equatable {
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

public struct DHTFailure: APIMessage, Equatable {
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
