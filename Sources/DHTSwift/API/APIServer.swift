import Foundation
import NIO
import NIOExtras
import UInt256

var dummyDict = [UInt256: [UInt8]]()

// MARK: - APIServer

public class APIServer {

    // MARK: Properties

    public let configuration: Configuration
    public let eventLoopGroup: EventLoopGroup
    public let bootstrap: ServerBootstrap
    private var channel: Channel?

    // MARK: Initializers

    public init(config: Configuration) {
        self.configuration = config
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.bootstrap = ServerBootstrap(group: self.eventLoopGroup)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

            // Set the handlers that are appled to the accepted Channels
            .childChannelInitializer { channel in
                // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
                channel.pipeline.addHandler(BackPressureHandler()).flatMap { _ in
                    channel.pipeline.addHandler(DebugInboundEventsHandler())
                }.flatMap { _ in
                    channel.pipeline.addHandler(DebugOutboundEventsHandler())
                }.flatMap { _ in
                    channel.pipeline.addHandler(ByteToMessageHandler<ByteToNetworkMessageDecoder>(ByteToNetworkMessageDecoder()))
                }.flatMap { _ in
                    channel.pipeline.addHandler(MessageToByteHandler<NetworkMessageToByteEncoder>(NetworkMessageToByteEncoder()))
                }.flatMap { _ in
                    channel.pipeline.addHandler(APIServerHandler())
                }
            }

            // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }

    // MARK: Public functions

    public func start() throws -> EventLoopFuture<Void> {
        let channel = try self.bootstrap.bind(host: configuration.apiAddress, port: configuration.apiPort).wait()
        self.channel = channel
        print("APIServer started and listening on \(channel.localAddress!)")
        return channel.closeFuture
    }

    public func stop() throws {
        try self.channel?.close().wait()
        try self.eventLoopGroup.syncShutdownGracefully()
    }
}
