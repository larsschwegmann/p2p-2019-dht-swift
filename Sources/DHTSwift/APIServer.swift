//
//  APIServer.swift
//  dht-module
//
//  Created by Lars Schwegmann on 11.06.19.
//

import Foundation
import NIO

var dummyDict: [String: [UInt8]] = ["hello": [0x00, 0x01, 0x02, 0x03]]

// MARK: - APIServer

public struct APIServer {

    // MARK: Properties

    public let configuration: Configuration
    public let eventLoopGroup: EventLoopGroup

    // MARK: Initializers

    public init(config: Configuration, eventLoopGroup: EventLoopGroup) {
        self.configuration = config
        self.eventLoopGroup = eventLoopGroup
    }

    // MARK: Public functions

    public func start() throws {
        let group = self.eventLoopGroup
        let bootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

            // Set the handlers that are appled to the accepted Channels
            .childChannelInitializer { channel in
                // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
                channel.pipeline.addHandler(BackPressureHandler()).flatMap { v in
                    channel.pipeline.addHandler(APIServerHandler())
                }
            }

            // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        defer {
            try! group.syncShutdownGracefully()
        }
        let channel = try bootstrap.bind(host: configuration.apiAddress, port: configuration.apiPort).wait()
        try channel.closeFuture.wait()

    }

    public func stop() {

    }
}

fileprivate final class APIServerHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        var byteBuffer = unwrapInboundIn(data)
        guard let bytes = byteBuffer.readBytes(length: byteBuffer.readableBytes) else {
            return
        }
        if let message = DHTGet.fromBytes(bytes) {
            guard let key = message.key.toString() else {
                return
            }
            guard let value = dummyDict[key] else {
                let failure = DHTFailure(key: message.key)
                let failureBytes = failure.getBytes()
                byteBuffer.writeBytes(failureBytes)
                context.write(wrapOutboundOut(byteBuffer), promise: nil)
                return
            }

            let success = DHTSuccess(key: message.key, value: value)
            let successBytes = success.getBytes()
            byteBuffer.writeBytes(successBytes)
            context.write(wrapOutboundOut(byteBuffer), promise: nil)
        } else if let _ = DHTPut.fromBytes(bytes) {
            return
        }
        //context.write(data, promise: nil)
    }

    // Flush it out. This can make use of gathering writes if multiple buffers are pending
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: ", error)

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }
}
