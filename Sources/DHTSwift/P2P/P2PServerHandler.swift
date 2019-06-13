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
        // TODO: Implement this
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
}

