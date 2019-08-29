import Foundation
import Logging
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
    var keyStore = Atomic([UInt256:[UInt8]]())
    var fingerTable = Atomic([Int: SocketAddress]()) // Use dict instead of array for safe conditional access
    var predecessor = Atomic<SocketAddress?>(nil)
    var successor: SocketAddress? {
        get {
            return fingerTable.value[0]
        }
        set {
            fingerTable.mutate { $0[0] = newValue }
        }
    }
    var currentAddress: SocketAddress {
        return try! SocketAddress(ipAddress: self.configuration.listenAddress, port: self.configuration.listenPort)
    }

    private var eventLoopGroup: EventLoopGroup
    private let timeout: TimeAmount
    private let configuration: Configuration
    private var stabilization: Stabilization?

    private let logger = Logger(label: "Chord")

    // MARK: Initializers

    public init(config: Configuration, timeout: TimeAmount = TimeAmount.seconds(10)) {
        self.configuration = config
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
        self.timeout = timeout
    }

    // MARK: -

    func responsibleFor(identifier: Identifier) throws -> Bool {
        guard let predecessor = self.predecessor.value else {
            throw ChordError.neverBootstrapped
        }
        let current = self.currentAddress
        let preID = Identifier.socketAddress(address: predecessor)
        let currentID = Identifier.socketAddress(address: current)
        return preID < identifier && identifier <= currentID
    }

    func responsibleFor(identifier: UInt256) throws -> Bool {
        guard let predecessor = self.predecessor.value else {
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
            logger.info("I am responsible for key \(identifier)")
            return self.currentAddress
        }
        logger.info("I am not resposible for key \(identifier)")
//        logger.info("My finger table: \(fingerTable.value)")
        let current = self.currentAddress
        let currentID = Identifier.socketAddress(address: current)
        let diff = identifier - currentID.hashValue!
        let zeros = diff.leadingZeroBitCount
        // TODO: is self.successor always not nil?
        logger.info("zeros: \(zeros), \(fingerTable.value[zeros]?.description ?? "nil"), \(self.successor?.description ?? "nil")")
        return fingerTable.value[zeros] ?? self.successor!
    }

    // MARK: - Public helper functions

    public func bootstrap() throws -> EventLoopFuture<Void> {
        logger.info("Bootstrapping without any peers, creating new network...")
        if let bootstrapAddress = self.configuration.bootstrapAddress,
            let bootstrapPort = self.configuration.bootstrapPort {
            return try self.bootstrap(bootstrapAddress: SocketAddress(ipAddress: bootstrapAddress, port: bootstrapPort))
        }
        let currentAddress = self.currentAddress
        for i in 0..<self.configuration.fingers {
            self.fingerTable.mutate { $0[i] = currentAddress }
        }
        self.predecessor.mutate { $0 = currentAddress }
        self.stabilization = Stabilization(eventLoopGroup: self.eventLoopGroup, config: self.configuration, chord: self)
        self.stabilization?.start()
        return self.eventLoopGroup.future()
    }

    /**
     Joins an existing Chord network using a known Bootstrap Peer
    */
    private func bootstrap(bootstrapAddress: SocketAddress) -> EventLoopFuture<Void> {
        logger.info("Starting bootstrap with Peer at \(bootstrapAddress)")
        self.stabilization = Stabilization(eventLoopGroup: self.eventLoopGroup, config: self.configuration, chord: self)
        let current = self.currentAddress
        let currentId = Identifier.socketAddress(address: current)
        let successorFuture = findPeer(forIdentifier: currentId, peerAddress: bootstrapAddress)

        let combined = successorFuture.flatMapThrowing { [weak self] successorAddress -> EventLoopFuture<SocketAddress> in
            self?.logger.info("Bootstrapping found successor: \(successorAddress)")
            // Update the finger table witho ourselves and our successor
            self?.fingerTable.mutate { $0 = [0: successorAddress] }
            guard let ref = self else {
                throw ChordError.missingSelf
            }
            for i in 1..<ref.configuration.fingers {
                ref.fingerTable.mutate { $0[i] = ref.currentAddress }
            }

            let predecessorFuture = ref.notifyPredecessor(address: current, peerAddress: successorAddress)
            predecessorFuture.whenSuccess { [weak self] predecessorAddress in
                // Update the predecessor address with our predecessor
                self?.predecessor.mutate { $0 = predecessorAddress }
                self?.logger.info("Bootstrapping found Predecessor: \(predecessorAddress)")
            }
            return predecessorFuture
        }

        return combined.map { [weak self] _ in
            self?.stabilization?.start()
            self?.logger.info("Started Stabilisation")
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
