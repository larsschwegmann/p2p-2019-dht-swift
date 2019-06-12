//
//  NetworkMessage.swift
//  DHTSwift
//
//  Created by Lars Schwegmann on 12.06.19.
//

import Foundation

// MARK: - API Message

/// NetworkMessage protocol for use with the APIServer and APIClient
public protocol NetworkMessage {
    static var messageTypeID: UInt16 { get }
    var serializedBody: [UInt8] { get }
    init?(serializedBodyBytes: [UInt8])
}

public extension NetworkMessage {

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
