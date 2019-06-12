//
//  APIServer.swift
//  dht-module
//
//  Created by Lars Schwegmann on 11.06.19.
//

import Foundation
import NIO

var dummyDict = [String: [UInt8]]()

// MARK: - APIServer

public class APIServer {

    // MARK: Properties

    public let configuration: Configuration
    public let eventLoopGroup: EventLoopGroup
    private var channel: Channel?

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
        self.channel = channel
        print("APIServer started and listening on \(channel.localAddress!)")
        try channel.closeFuture.wait()
    }

    public func stop() throws {
        try channel?.close().wait()
    }
}

fileprivate final class APIServerHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    // MARK: ChannelInboundHandler protocol functions

    public func channelActive(context: ChannelHandlerContext) {
        print("APIServer: Client connected from \(context.remoteAddress!)")
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        var byteBuffer = unwrapInboundIn(data)
        guard let bytes = byteBuffer.readBytes(length: byteBuffer.readableBytes) else {
            return
        }
        if let message = DHTGet.fromBytes(bytes) {
            // DHT GET Request
            guard let key = message.key.toString(size: 32) else {
                print("APIServer: Got invalid key for DHT GET: \(message.key)")
                self.sendFailure(key: message.key, context: context)
                return
            }
            print("APIServer: Got DHT GET request for key \(message.key)")
            guard let value = dummyDict[key] else {
                print("APIServer: Could not find value for key \(message.key)")
                self.sendFailure(key: message.key, context: context)
                return
            }

            let success = DHTSuccess(key: message.key, value: value)
            let successBytes = success.getBytes()
            var writeBuffer = context.channel.allocator.buffer(capacity: successBytes.count)
            writeBuffer.writeBytes(successBytes)
            print("APIServer: Sent DHTSuccess \(success) for key \(key)")
            context.write(wrapOutboundOut(writeBuffer), promise: nil)
        } else if let message = DHTPut.fromBytes(bytes) {
            // DHT PUT Request
            guard let key = message.key.toString(size: 32) else {
                print("APIServer: Got invalid key for DHT PUT: \(message.key)")
                return
            }
            print("APIServer: GOT DHT PUT request for key \(message.key), value \(message.value)")
            dummyDict[key] = message.value
            context.close(promise: nil)
        }
    }

    // Flush it out. This can make use of gathering writes if multiple buffers are pending
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
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

    // MARK: Private functions

    private func sendFailure(key: [UInt8], context: ChannelHandlerContext) {
        let failure = DHTFailure(key: key)
        let failureBytes = failure.getBytes()
        var writeBuffer = context.channel.allocator.buffer(capacity: failureBytes.count)
        writeBuffer.writeBytes(failureBytes)
        context.write(wrapOutboundOut(writeBuffer), promise: nil)
        print("APIServer: Sent failure \(failure) for key \(key)")
    }
}
