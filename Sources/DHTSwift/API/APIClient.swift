//
//  APIClient.swift
//  dht-module
//
//  Created by Dimitri Tyan on 11.06.19.
//

import Foundation
import NIO

public class APICLient {
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let address: String
    let port: Int

    public init(address: String, port: Int) {
        self.address = address
        self.port = port
    }

    func start() throws {
        do {
            let channel = try bootstrap.connect(host: address, port: port).wait()
            try channel.closeFuture.wait()
        } catch let error {
            throw error
        }
    }

    func stop() {
        do {
            try group.syncShutdownGracefully()
        } catch let error {
            print("Error shutting down \(error.localizedDescription)")
            exit(0)
        }
        print("Client connection closed")
    }

    private var bootstrap: ClientBootstrap {
        return ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(APIClientHandler())
        }

    }

    // MARK: - handleGet
    public func handleGet(with key: String) {
        var keyAsBytes : [UInt8] = []
        guard let i = UInt8(key) else {
            print("asdf")
            return
        }
        keyAsBytes[0] = UInt8(0)
        keyAsBytes[1] = UInt8(0)
        keyAsBytes[2] = UInt8(0)
        keyAsBytes[3] = i

        DHTGet(key: keyAsBytes)
    }

    // MARK: - handlePut
    public func handlePut(with key: String, value: String) {

    }
}

class APIClientHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    private var numBytes = 0

    // channel is connected, send a message
    func channelActive(ctx: ChannelHandlerContext) {
        let message = "SwiftNIO rocks!"
        var buffer = ctx.channel.allocator.buffer(capacity: message.utf8.count)
        buffer.writeString(message)
        ctx.writeAndFlush(wrapOutboundOut(buffer), promise: nil)
    }

    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        let readableBytes = buffer.readableBytes
        if let received = buffer.readString(length: readableBytes) {
            print(received)
        }
        if numBytes == 0 {
            print("nothing left to read, close the channel")
            ctx.close(promise: nil)
        }
    }

    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: \(error.localizedDescription)")
        ctx.close(promise: nil)
    }
}
