import Foundation
import NIO
import UInt256

final class APIServerHandler: ChannelInboundHandler {
    public typealias InboundIn = NetworkMessage
    public typealias OutboundOut = NetworkMessage

    // MARK: ChannelInboundHandler protocol functions

    public func channelActive(context: ChannelHandlerContext) {
        print("APIServer: Client connected from \(context.remoteAddress!)")
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let message = unwrapInboundIn(data)
        let chord = Chord.shared
        switch message {
        case let get as DHTGet:
            // DHT GET Request
            print("APIServer: Got DHT GET request for key \(get.key)")
            for i in 0...UInt8.max {
                let key = Identifier.Key(rawKey: get.key, replicationIndex: i)
                let id = Identifier.key(key)
                guard let peerFuture = try? self.findPeer(identifier: id) else {
                    fatalError("Could not find Peer for key \(get.key)")
                }
                let getFuture = peerFuture.flatMap { peerAddress in
                    chord.getValue(key: key, peerAddress: peerAddress)
                }

                getFuture.whenSuccess { [weak self] value in
                    let success = DHTSuccess(key: get.key, value: value)
                    guard let data = self?.wrapOutboundOut(success) else {
                        fatalError("self is nil")
                    }
                    context.writeAndFlush(data, promise: nil)
                }

                getFuture.whenFailure { [weak self] error in
                    let failure = DHTFailure(key: get.key)
                    guard let data = self?.wrapOutboundOut(failure) else {
                        fatalError("self is nil")
                    }
                    context.writeAndFlush(data, promise: nil)
                }
            }
        case let put as DHTPut:
            print("APIServer: Got DHT PUT request with key \(put.key) value \(put.value)")
        default:
            return
        }
    }

    func channelUnregistered(context: ChannelHandlerContext) {
        print("APIServer: Connection to client at \(context.remoteAddress!) closed")
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("APIServer: Unexpected error: ", error)

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }

    // MARK: Private helper functions

    private func findPeer(identifier: Identifier) throws -> EventLoopFuture<SocketAddress> {
        let chord = Chord.shared
        let peer = try chord.closestPeer(identifier: identifier)
        return chord.findPeer(forIdentifier: identifier, peerAddress: peer)
    }
}
