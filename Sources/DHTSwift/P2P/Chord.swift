import Foundation
import NIO
import UInt256

// MARK: Chord Error

enum ChordError: LocalizedError {
    case neverBootstrapped
    case unexpectedResponseFromPeer(NetworkMessage)
    case storageFailure(key: UInt256)

    case missingSelf
}

// MARK: Chord

public final class Chord {

    // MARK: Properties

    var keyStore = [UInt256: [UInt8]]()
    var fingerTable = [Int: SocketAddress]() // Use dict instead of array for safe conditional access
    var predecessor: SocketAddress?
    var successor: SocketAddress? {
        get {
            return fingerTable[0]
        }
        set {
            fingerTable[0] = newValue
        }
    }
    var currentAddress: SocketAddress {
        return try! SocketAddress(ipAddress: self.configuration.listenAddress, port: self.configuration.listenPort)
    }

    private var eventLoopGroup: EventLoopGroup
    private let timeout: TimeAmount
    private let configuration: Configuration
    private var stabilization: Stabilization?

    // MARK: Initializers

    public init(config: Configuration, timeout: TimeAmount = TimeAmount.seconds(10)) {
        self.configuration = config
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
        self.timeout = timeout
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

    func responsibleFor(identifier: UInt256) throws -> Bool {
        guard let predecessor = self.predecessor else {
            throw ChordError.neverBootstrapped
        }
        let current = self.currentAddress
        let preID = Identifier.socketAddress(address: predecessor)
        let currentID = Identifier.socketAddress(address: current)
        return preID.hashValue! < identifier && identifier <= currentID.hashValue!
    }

    func closestPeer(identifier: Identifier) throws -> SocketAddress {
        return try closestPeer(identifier: identifier.hashValue!)
    }

    func closestPeer(identifier: UInt256) throws -> SocketAddress {
        if try self.responsibleFor(identifier: identifier) {
            return self.currentAddress
        }
        let current = self.currentAddress
        let currentID = Identifier.socketAddress(address: current)
        let diff = identifier - currentID.hashValue!
        let zeros = diff.leadingZeroBitCount
        return fingerTable[zeros] ?? self.successor!
    }

    // MARK: - Public helper functions

    public func bootstrap() throws -> EventLoopFuture<Void> {
        if let bootstrapAddress = self.configuration.bootstrapAddress,
            let bootstrapPort = self.configuration.bootstrapPort {
            return try self.bootstrap(bootstrapAddress: SocketAddress(ipAddress: bootstrapAddress, port: bootstrapPort))
        }
        let currentAddress = self.currentAddress
        for i in 0..<self.configuration.fingers {
            self.fingerTable[i] = currentAddress
        }
        self.predecessor = currentAddress
        self.stabilization = Stabilization(eventLoopGroup: self.eventLoopGroup, config: self.configuration, chord: self)
        self.stabilization?.start()
        return self.eventLoopGroup.future()
    }

    /**
     Joins an existing Chord network using a known Bootstrap Peer
    */
    private func bootstrap(bootstrapAddress: SocketAddress) -> EventLoopFuture<Void> {
        self.stabilization = Stabilization(eventLoopGroup: self.eventLoopGroup, config: self.configuration, chord: self)
        let current = self.currentAddress
        let currentId = Identifier.socketAddress(address: current)
        let successorFuture = findPeer(forIdentifier: currentId, peerAddress: bootstrapAddress)

        let combined = successorFuture.flatMapThrowing { [weak self] successorAddress -> EventLoopFuture<SocketAddress> in
            // Update the finger table witho ourselves and our successor
            self?.fingerTable = [0: successorAddress]
            guard let ref = self else {
                throw ChordError.missingSelf
            }
            for i in 1..<ref.configuration.fingers {
                ref.fingerTable[i] = ref.currentAddress
            }

            let predecessorFuture = ref.notifyPredecessor(address: current, peerAddress: successorAddress)
            predecessorFuture.whenSuccess { [weak self] predecessorAddress in
                // Update the predecessor address with our predecessor
                self?.predecessor = predecessorAddress
            }
            return predecessorFuture
        }

        return combined.map { [weak self] _ in
            self?.stabilization?.start()
            return ()
        }
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
