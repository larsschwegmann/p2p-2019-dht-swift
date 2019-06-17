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
                    channel.pipeline.addHandler(ByteToMessageHandler<ByteToNetworkMessageDecoder>(ByteToNetworkMessageDecoder()))
                }.flatMap{ _ in
                    channel.pipeline.addHandler(RequestResponseHandler<NetworkMessage, NetworkMessage>())
                }.flatMap { _ in
                    channel.pipeline.addHandler(MessageToByteHandler<NetworkMessageToByteEncoder>(NetworkMessageToByteEncoder()))
                }
        }
    }

    func request(socketAddress: SocketAddress, requestMessage: NetworkMessage) -> EventLoopFuture<NetworkMessage> {
        let channelFuture = bootstrap.connect(to: socketAddress)
        let retFuture = channelFuture.flatMap { channel -> EventLoopFuture<NetworkMessage> in
            let promise = channel.eventLoop.makePromise(of: NetworkMessage.self)
            return channel.pipeline.addHandler(P2PClientHandler(request: requestMessage, promise: promise)).flatMap({ _ -> EventLoopFuture<NetworkMessage> in
                return promise.futureResult
            })
        }

        retFuture.whenComplete { _ in
            channelFuture.whenComplete({ result in
                switch result {
                case .success(let channel):
                    try? channel.close().wait()
                case .failure(_):
                    return
                }
            })
        }

        return retFuture
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
