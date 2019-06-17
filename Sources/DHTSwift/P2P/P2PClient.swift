import Foundation
import NIO
import NIOExtras

// MARK: - P2PClient

class P2PClient {

    // MARK: Properties

    let eventLoopGroup: EventLoopGroup
    let bootstrap: ClientBootstrap

    // MARK: Initalizers

    init(eventLoopGroup: EventLoopGroup, timeout: TimeAmount) {
        self.eventLoopGroup = eventLoopGroup
        self.bootstrap = ClientBootstrap(group: self.eventLoopGroup)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .connectTimeout(timeout)
            .channelInitializer { channel in
                channel.pipeline.addHandler(DebugInboundEventsHandler()).flatMap { _ in
                    channel.pipeline.addHandler(DebugOutboundEventsHandler())
                }.flatMap { _ in
                    channel.pipeline.addHandler(ByteToMessageHandler<ByteToNetworkMessageDecoder>(ByteToNetworkMessageDecoder()), name: "byteToMessage")
                }.flatMap{ _ in
                    channel.pipeline.addHandler(MessageToByteHandler<NetworkMessageToByteEncoder>(NetworkMessageToByteEncoder()), name: "messageToByte")
                }.flatMap { _ in
                    channel.pipeline.addHandler(RequestResponseHandler<NetworkMessage, NetworkMessage>(), name: "request-response")
                }
        }
    }

    func request(socketAddress: SocketAddress, requestMessage: NetworkMessage) -> EventLoopFuture<NetworkMessage> {
        let channelFuture = bootstrap.connect(to: socketAddress)
        let retFuture = channelFuture.flatMap { channel -> EventLoopFuture<NetworkMessage> in
            let promise = channel.eventLoop.makePromise(of: NetworkMessage.self)
            return channel.pipeline.addHandler(P2PClientHandler(request: requestMessage, promise: promise), name: "P2PClientHandler").flatMap({ _ -> EventLoopFuture<NetworkMessage> in
                return promise.futureResult
            })
        }

        return retFuture.flatMap { message -> EventLoopFuture<NetworkMessage> in
            return channelFuture.flatMap { channel -> EventLoopFuture<NetworkMessage> in
                return channel.close().map { _ -> NetworkMessage in
                    return message
                }
            }
        }
    }
}

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
