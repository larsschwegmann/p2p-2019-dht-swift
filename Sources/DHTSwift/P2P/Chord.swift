import Foundation
import NIO
import UInt256
import AsyncKit

// MARK: Chord Error

enum ChordError: LocalizedError {
    case unexpectedResponseFromPeer(NetworkMessage)
    case storageFailure(key: UInt256)
}

// MARK: Chord

class Chord {

    // MARK: Singleton

    static let shared = Chord()

    // MARK: Properties

    private static var configuration: Configuration?

    var keyStore = [UInt256: [UInt8]]()
    var fingerTable = [Int: SocketAddress]() // Use dict instead of array for safe conditional access
    var predecessor: SocketAddress?

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

    static func setup(_ config: Configuration) {
        Chord.configuration = config
    }

    // MARK: Public functions

    /**
     Joins an existing Chord network using a known Bootstrap Peer
    */
    func bootstrap(bootstrapAddress: SocketAddress) -> EventLoopFuture<Void> {
        // Our id
        let currentAddress = try! SocketAddress(ipAddress: self.configuration.listenAddress, port: self.configuration.listenPort)
        guard let currentId = Identifier.socketAddress(address: currentAddress).hashValue else {
            fatalError("Could not obtain SHA256 hash of address: \(currentAddress)")
        }
        let successorFuture = findPeer(forKey: currentId, peerAddress: bootstrapAddress)
        let predecessorFuture = notifyPredecessor(address: currentAddress, peerAddress: bootstrapAddress)

        predecessorFuture.whenSuccess { [weak self] predecessorAddress in
            // Update the predecessor address with our predecessor
            self?.predecessor = predecessorAddress
        }

        successorFuture.whenSuccess { [weak self] successorAddress in
            // Update the finger table witho ourselves and our successor
            self?.fingerTable = [0: currentAddress, 1: successorAddress]
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
    func findPeer(forKey key: UInt256, peerAddress: SocketAddress) -> EventLoopFuture<SocketAddress> {
        let client = P2PClient(eventLoopGroup: self.eventLoopGroup, timeout: self.timeout)
        let message = P2PPeerFind(key: key)
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
