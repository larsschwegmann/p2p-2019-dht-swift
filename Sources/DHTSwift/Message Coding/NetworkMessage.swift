import Foundation

// MARK: - NetworkMessageTypeID

/**
 Enumeration of all Message Type IDs handled by the module.
 Cases prefixed with 'DHT' correspond to the API Interface of the module.
 Case prefixed with 'P2P' correspond to the inter-module interface or PeerToPeer interface of the module
 */
public enum NetworkMessageTypeID: UInt16 {
    case DHTPutID                   = 650
    case DHTGetID                   = 651
    case DHTSuccessID               = 652
    case DHTFailureID               = 653
    case P2PStorageGetID            = 1000
    case P2PStoragePutID            = 1001
    case P2PStorageGetSuccessID     = 1002
    case P2PStoragePutSuccessID     = 1003
    case P2PStorageFailureID        = 1004
    case P2PPeerFindID              = 1050
    case P2PPeerFoundID             = 1051
    case P2PPredecessorNotifyID     = 1052
    case P2PPredecessorReplyID      = 1053
    case P2PSuccessorRequestID      = 1080
    case P2PSuccessorReplyID        = 1081
    case P2PPingRequestID           = 1082
    case P2PPongReplyID             = 1083
    case P2PDeadConnectionReplyID   = 1084 // Pseudo

    func getType() -> NetworkMessage.Type {
        switch self {
        case .DHTPutID:
            return DHTPut.self
        case .DHTGetID:
            return DHTGet.self
        case .DHTSuccessID:
            return DHTSuccess.self
        case .DHTFailureID:
            return DHTFailure.self
        case .P2PStorageGetID:
            return P2PStorageGet.self
        case .P2PStoragePutID:
            return P2PStoragePut.self
        case .P2PStorageGetSuccessID:
            return P2PStorageGetSuccess.self
        case .P2PStoragePutSuccessID:
            return P2PStoragePutSuccess.self
        case .P2PStorageFailureID:
            return P2PStorageFailure.self
        case .P2PPeerFindID:
            return P2PPeerFind.self
        case .P2PPeerFoundID:
            return P2PPeerFound.self
        case .P2PPredecessorNotifyID:
            return P2PPredecessorNotify.self
        case .P2PPredecessorReplyID:
            return P2PPredecessorReply.self
        case .P2PSuccessorRequestID:
            return P2PSuccessorRequest.self
        case .P2PSuccessorReplyID:
            return P2PSuccessorReply.self
        case .P2PPingRequestID:
            return P2PPingRequest.self
        case .P2PPongReplyID:
            return P2PPongReply.self
        case .P2PDeadConnectionReplyID:
            return P2PDeadConnectionReply.self
        }
    }
}

// MARK: - NetworkMessage

/// NetworkMessage protocol for use with the APIServer and APIClient
public protocol NetworkMessage {
    static var messageTypeID: NetworkMessageTypeID { get }
    var serializedBody: [UInt8] { get }
    init?(serializedBodyBytes: [UInt8])
}

public extension NetworkMessage {

    /// Serializes an entire NetworkMessage to a byte array including the message header with size and message
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
        var messageTypeIDBigEndian = messageTypeID.rawValue.bigEndian
        let messageTypeIDBytes = withUnsafeBytes(of: &messageTypeIDBigEndian, { $0 })
        bytes.append(contentsOf: messageTypeIDBytes)

        // Body
        bytes.append(contentsOf: messageBody)

        return bytes
    }

    /// Tries to create an APIMessage object from a given byte array
    static func fromBytes(_ bytes: [UInt8]) -> Self? {
        guard bytes.count >= 4 else {
            // Message Header is missing
            return nil
        }
        let messageTypeIDRaw = bytes[2...3].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
        guard let messageTypeID = NetworkMessageTypeID(rawValue: messageTypeIDRaw),
            messageTypeID == Self.messageTypeID else {
            return nil
        }
        let messageBody = bytes.count > 4 ? Array(bytes[4...]) : []
        return Self(serializedBodyBytes: messageBody)
    }
}
