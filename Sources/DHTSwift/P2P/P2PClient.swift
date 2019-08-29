import Foundation
import Logging
import NIO
import NIOExtras

// MARK: - P2PClient

final class P2PClient {

    // MARK: Properties

    let eventLoopGroup: EventLoopGroup
    let bootstrap: ClientBootstrap

    private let logger = Logger(label: "P2PClient")

    // MARK: Initalizers

    init(eventLoopGroup: EventLoopGroup, timeout: TimeAmount) {
        self.eventLoopGroup = eventLoopGroup
        self.bootstrap = ClientBootstrap(group: self.eventLoopGroup)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .connectTimeout(timeout)
            .channelInitializer { channel in
                channel.pipeline.addHandler(ByteToMessageHandler<ByteToNetworkMessageDecoder>(ByteToNetworkMessageDecoder()), name: "byteToMessage").flatMap{ _ in
                    channel.pipeline.addHandler(MessageToByteHandler<NetworkMessageToByteEncoder>(NetworkMessageToByteEncoder()), name: "messageToByte")
                }.flatMap { _ in
                    channel.pipeline.addHandler(RequestResponseHandler<NetworkMessage, NetworkMessage>(), name: "request-response")
                }
        }
    }

    func request(socketAddress: SocketAddress, requestMessage: NetworkMessage) -> EventLoopFuture<NetworkMessage> {
        logger.debug("Sending request to \(socketAddress) with message: \(requestMessage)")
        let channelFuture = bootstrap.connect(to: socketAddress)
        let retFuture = channelFuture.flatMap { channel -> EventLoopFuture<NetworkMessage> in
            let promise = channel.eventLoop.makePromise(of: NetworkMessage.self)
            return channel.pipeline.addHandler(P2PClientHandler(request: requestMessage, promise: promise), name: "P2PClientHandler").flatMap({ [weak self] _ -> EventLoopFuture<NetworkMessage> in
                self?.logger.info("Sent request to \(socketAddress) -> \(requestMessage)")
                return promise.futureResult
            })
        }

        return retFuture.flatMap { message -> EventLoopFuture<NetworkMessage> in
            return channelFuture.flatMap { channel -> EventLoopFuture<NetworkMessage> in
                return channel.close().map { [weak self] _ -> NetworkMessage in
                    self?.logger.info("Got response: \(message) from \(socketAddress), closed request channel")
                    return message
                }
            }
        }
    }
}
