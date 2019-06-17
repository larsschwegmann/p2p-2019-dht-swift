import Foundation
import NIO
import UInt256
import AsyncKit

// MARK: Chord Error

enum ChordError: LocalizedError {
    case missingConfiguration
    case neverBootstrapped
    case unexpectedResponseFromPeer(NetworkMessage)
    case storageFailure(key: UInt256)
}

// MARK: Chord

public class Chord {

    // MARK: Singleton

    public static let shared = Chord()

    // MARK: Properties

    private static var configuration: Configuration?

    var keyStore = [UInt256: [UInt8]]()
    var fingerTable = [Int: SocketAddress]() // Use dict instead of array for safe conditional access
    var predecessor: SocketAddress?
    var successor: SocketAddress? {
        return fingerTable[0]
    }
    var currentAddress: SocketAddress {
        return try! SocketAddress(ipAddress: self.configuration.listenAddress, port: self.configuration.listenPort)
    }

    private var eventLoopGroup: EventLoopGroup
    private let timeout: TimeAmount
    private let configuration: Configuration

    // MARK: Initializers

    private init(timeout: TimeAmount = TimeAmount.seconds(10)) {
        guard let config = Chord.configuration else {
            fatalError("No config was supplied for Chord shared instance")
        }
        self.configuration = config
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
        self.timeout = timeout
    }

    // MARK: Static setup for shared singleton

    public static func setup(_ config: Configuration) {
        Chord.configuration = config
    }

    // MARK: -

    func responsibleFor(identifier: Identifier) throws -> Bool {
        guard let predecessor = self.predecessor else {
            throw ChordError.neverBootstrapped
        }
        let current = self.currentAddress
        let preID = Identifier.socketAddress(address: predecessor)
        let currentID = Identifier.socketAddress(address: current)
        return preID < identifier && identifier <= currentID
    }

    func closestPeer(identifier: Identifier) throws -> SocketAddress {
        if try self.responsibleFor(identifier: identifier) {
            return self.currentAddress
        }
        let current = self.currentAddress
        let currentID = Identifier.socketAddress(address: current)
        let diff = identifier.hashValue! - currentID.hashValue!
        let zeros = diff.leadingZeroBitCount
        return fingerTable[zeros] ?? self.successor!
    }

    // MARK: Public helper functions


    func bootstrap() {
        let currentAddress = self.currentAddress
        for i in 0..<self.configuration.fingers {
            self.fingerTable[i] = currentAddress
        }
        self.predecessor = currentAddress
    }

    /**
     Joins an existing Chord network using a known Bootstrap Peer
    */
    func bootstrap(bootstrapAddress: SocketAddress) -> EventLoopFuture<Void> {
        let current = self.currentAddress
        let currentId = Identifier.socketAddress(address: current)
        let successorFuture = findPeer(forIdentifier: currentId, peerAddress: bootstrapAddress)
        let predecessorFuture = notifyPredecessor(address: current, peerAddress: bootstrapAddress)

        predecessorFuture.whenSuccess { [weak self] predecessorAddress in
            // Update the predecessor address with our predecessor
            self?.predecessor = predecessorAddress
        }

        successorFuture.whenSuccess { [weak self] successorAddress in
            // Update the finger table witho ourselves and our successor
            self?.fingerTable = [0: successorAddress]
            guard let ref = self else {
                return
            }
            for i in 1..<ref.configuration.fingers {
                ref.fingerTable[i] = ref.currentAddress
            }
        }

        // TODO: Un-Unglify this
        return predecessorFuture.flatMap({ predecessorFuture -> EventLoopFuture<Void> in
            return successorFuture.map({ successorFuture -> Void in
                return ()
            })
        })
    }

    /**
     Finds the peer responsible for the given key
    */
    func findPeer(forIdentifier identifier: Identifier, peerAddress: SocketAddress) -> EventLoopFuture<SocketAddress> {
        let hash = identifier.hashValue!
        let client = P2PClient(eventLoopGroup: self.eventLoopGroup, timeout: self.timeout)
        let message = P2PPeerFind(key: hash)
        return client.request(socketAddress: peerAddress, requestMessage: message).flatMapThrowing { response -> SocketAddress in
            switch response {
            case let peerFound as P2PPeerFound:
                return try SocketAddress(ipv6Bytes: peerFound.ipAddr, port: peerFound.port)
            default:
                throw ChordError.unexpectedResponseFromPeer(response)
            }
        }
    }

    func getValue(key: Identifier.Key, peerAddress: SocketAddress) -> EventLoopFuture<[UInt8]> {
        let client = P2PClient(eventLoopGroup: self.eventLoopGroup, timeout: self.timeout)
        let message = P2PStorageGet(replicationIndex: key.replicationIndex, key: key.rawKey)
        return client.request(socketAddress: peerAddress, requestMessage: message).flatMapThrowing { response -> [UInt8] in
            switch response {
            case let success as P2PStorageGetSuccess:
                return success.value
            case let failure as P2PStorageFailure:
                throw ChordError.storageFailure(key: failure.key)
            default:
                throw ChordError.unexpectedResponseFromPeer(response)
            }
        }
    }

    func putValue(key: Identifier.Key, value: [UInt8], ttl: UInt16, peerAddress: SocketAddress) -> EventLoopFuture<Void> {
        let client = P2PClient(eventLoopGroup: self.eventLoopGroup, timeout: self.timeout)
        let message = P2PStoragePut(ttl: ttl,
                                    replicationIndex: key.replicationIndex,
                                    key: key.rawKey,
                                    value: value)
        return client.request(socketAddress: peerAddress, requestMessage: message).flatMapThrowing({ response in
            switch response {
            case _ as P2PStoragePutSuccess:
                return
            case let failure as P2PStorageFailure:
                throw ChordError.storageFailure(key: failure.key)
            default:
                throw ChordError.unexpectedResponseFromPeer(response)
            }
        })
    }

    func notifyPredecessor(address: SocketAddress, peerAddress: SocketAddress) -> EventLoopFuture<SocketAddress> {
        let client = P2PClient(eventLoopGroup: self.eventLoopGroup, timeout: self.timeout)
        let message = P2PPredecessorNotify(ipAddr: address.getIPv6Bytes()!, port: UInt16(address.port ?? 0))
        return client.request(socketAddress: peerAddress, requestMessage: message).flatMapThrowing({ response in
            switch response {
            case let reply as P2PPredecessorReply:
                return try SocketAddress(ipv6Bytes: reply.ipAddr, port: reply.port)
            default:
                throw ChordError.unexpectedResponseFromPeer(response)
            }
        })
    }

}