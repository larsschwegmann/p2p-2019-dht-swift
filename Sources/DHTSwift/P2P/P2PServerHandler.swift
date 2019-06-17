import Foundation
import NIO
import UInt256

final class P2PServerHandler: ChannelInboundHandler {
    public typealias InboundIn = NetworkMessage
    public typealias OutboundOut = NetworkMessage

    // MARK: ChannelInboundHandler protocol functions

    public func channelActive(context: ChannelHandlerContext) {
        print("P2PServer: Client connected from \(context.remoteAddress!)")
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let message = unwrapInboundIn(data)
        switch message {
        case let find as P2PPeerFind:
            print("P2PServer: Received Peer Find for key \(find.key)")
            let chord = Chord.shared
            guard let peer = try? chord.closestPeer(identifier: find.key) else {
                print("P2PServer: Could not find closest peer for id \(find.key)")
                context.close(promise: nil)
                return
            }
            let found = P2PPeerFound(key: find.key, ipAddr: peer.getIPv6Bytes()!, port: UInt16(peer.port!))
            print("Found Peer for key \(find.key): \(peer.description)")
            context.writeAndFlush(wrapOutboundOut(found), promise: nil)
        case let notify as P2PPredecessorNotify:
            guard let addr = try? SocketAddress(ipv6Bytes: notify.ipAddr, port: notify.port) else {
                print("P2PServer: Could not decode IPv6 address from bytes: \(notify.ipAddr)")
                context.close(promise: nil)
                return
            }

            print("P2PServer; Received Predecessor Notify with address")
        default:
            print("P2PServer: Got unexpected message \(message)")
            return
        }
    }

    // Flush it out. This can make use of gathering writes if multiple buffers are pending
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    func channelUnregistered(context: ChannelHandlerContext) {
        print("P2PServer: Connection to client at \(context.remoteAddress!) closed")
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("P2PServer: Unexpected error: ", error)

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }

    // MARK: Private helper functions
}

