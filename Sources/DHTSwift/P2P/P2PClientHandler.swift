import Foundation
import NIO
import NIOExtras

// MARK: - P2PClientHandler

final class P2PClientHandler: ChannelInboundHandler {
    typealias InboundIn = NIOAny
    typealias OutboundOut = (NetworkMessage, EventLoopPromise<NetworkMessage>)

    // MARK: Properties

    let request: NetworkMessage
    let promise: EventLoopPromise<NetworkMessage>

    // MARK: Initializers

    init(request: NetworkMessage, promise: EventLoopPromise<NetworkMessage>) {
        self.request = request
        self.promise = promise
    }

    // MARK: ChannelInboundHandler protocol

    func channelActive(context: ChannelHandlerContext) {
        context.writeAndFlush(wrapOutboundOut((self.request, promise)), promise: nil)
    }

}
