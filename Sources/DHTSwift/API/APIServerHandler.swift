import Foundation
import Logging
import NIO
import UInt256

final class APIServerHandler: ChannelInboundHandler {
    public typealias InboundIn = NetworkMessage
    public typealias OutboundOut = NetworkMessage

    private let chord: Chord

    private let logger = Logger(label: "APIServerHandler")

    public init(chord: Chord) {
        self.chord = chord
    }

    // MARK: ChannelInboundHandler protocol functions

    public func channelActive(context: ChannelHandlerContext) {
        //logger.debug("Client connected from \(context.remoteAddress!)")
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let message = unwrapInboundIn(data)
        switch message {
        case let get as DHTGet:
            // DHT GET Request
            logger.info("Got DHT GET request \(get)")
            // TODO change the limit here
            for i in 0...UInt8(1) {
                let key = Identifier.Key(rawKey: get.key, replicationIndex: i)
                let id = Identifier.key(key)
                guard let peerFuture = try? self.findPeer(identifier: id) else {
                    fatalError("Could not find Peer for key \(get.key)")
                }
                let getFuture = peerFuture.flatMap { peerAddress in
                    self.chord.getValue(key: key, peerAddress: peerAddress)
                }.hop(to: context.eventLoop)

                getFuture.whenSuccess { [weak self] value in
                    let success = DHTSuccess(key: get.key, value: value)
                    guard let data = self?.wrapOutboundOut(success) else {
                        fatalError("self is nil")
                    }
                    self?.logger.info("Successfully got \(success)")
                    context.writeAndFlush(data, promise: nil)
                    context.close(promise: nil)
                }

                getFuture.whenFailure { [weak self] error in
                    let failure = DHTFailure(key: get.key)
                    guard let data = self?.wrapOutboundOut(failure) else {
                        fatalError("self is nil")
                    }
                    self?.logger.error("Failed to get \(failure)")
                    context.writeAndFlush(data, promise: nil)
                }
            }
        case let put as DHTPut:
            logger.info("Got DHT PUT request \(put)")
            for i in 0...put.replication {
                let key = Identifier.Key(rawKey: put.key, replicationIndex: i)
                guard let peerFuture = try? self.findPeer(identifier: Identifier.key(key)) else {
                    fatalError("Could not find Peer for key \(put.key)")
                }
                let putFuture = peerFuture.map { peerAddress in
                    self.chord.putValue(key: key, value: put.value, ttl: put.ttl, peerAddress: peerAddress)
                }.hop(to: context.eventLoop)
                putFuture.whenSuccess { [weak self] _ in
                    let success = DHTSuccess(key: put.key, value: put.value)
                    guard let data = self?.wrapOutboundOut(success) else {
                        fatalError("self is nil")
                    }
                    self?.logger.info("Successfully put \(success)")
                    context.writeAndFlush(data, promise: nil)
                }
                putFuture.whenFailure { [weak self] error in
                    let failure = DHTFailure(key: put.key)
                    guard let data = self?.wrapOutboundOut(failure) else {
                        fatalError("self is nil")
                    }
                    self?.logger.error("Failed to put \(failure)")
                    context.writeAndFlush(data, promise: nil)
                }
            }
        default:
            return
        }
    }

    func channelUnregistered(context: ChannelHandlerContext) {
        //logger.info("Connection to client at \(context.remoteAddress!) closed")
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("Unexpected error: \(error)")

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }

    // MARK: Private helper functions

    private func findPeer(identifier: Identifier) throws -> EventLoopFuture<SocketAddress> {
        let peer = try chord.closestPeer(identifier: identifier)
        return chord.findPeer(forIdentifier: identifier, peerAddress: peer)
    }
}
