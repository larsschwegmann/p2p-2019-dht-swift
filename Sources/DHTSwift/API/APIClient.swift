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

    public func start(payload: [UInt8]) throws {
        let requestPayload = payload

        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(APIClientHandler(requestPayload: requestPayload))
        }

        do {
            let channel = try bootstrap.connect(host: address, port: port).wait()
            print("Connected to host with ip \(address) on port \(port)")
            try channel.closeFuture.wait()
        } catch let error {
            throw error
        }
    }

    public func stop() {
        do {
            try group.syncShutdownGracefully()
        } catch let error {
            print("Error shutting down \(error.localizedDescription)")
            exit(0)
        }
        print("Client connection closed")
    }

    // MARK: - handleGet
    public func handleGet(with key: String) -> [UInt8] {
        let dhtGet = DHTGet(key: key.toByteArray(cut: 32))
        return dhtGet.getBytes()
    }

    // MARK: - handlePut
    public func handlePut(with key: String, value: String) -> [UInt8] {
        let dhtPut = DHTPut(ttl: 1, replication: 1, key: key.toByteArray(cut: 32), value: value.toByteArray(cut: value.utf8.count))
        return dhtPut.getBytes()
    }
}

class APIClientHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    let requestPayload: [UInt8]

    private var numBytes = 0

    init(requestPayload: [UInt8]) {
        self.requestPayload = requestPayload
    }

    // channel is connected, send a message
    func channelActive(context: ChannelHandlerContext) {
        var buffer = context.channel.allocator.buffer(capacity: requestPayload.count)

        self.numBytes = buffer.readableBytes
        context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)

        buffer.writeBytes(requestPayload)
        context.writeAndFlush(wrapOutboundOut(buffer), promise: nil)
        print("Send message to server")
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        let readableBytes = buffer.readableBytes

        guard let message = buffer.readBytes(length: readableBytes) else {
            print("[Error]: Could not read bytes")
            return
        }

        if let dhtSuccess = DHTSuccess.fromBytes(message) {
            print("[Success]: Found value \(dhtSuccess.value) for key \(dhtSuccess.key)")
        } else if let dhtFailure = DHTFailure.fromBytes(message) {
            print("[Error] Could not find value for key \(dhtFailure.key)")
        }

        if numBytes == 0 {
            print("nothing left to read, close the channel")
            context.close(promise: nil)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: \(error.localizedDescription)")
        context.close(promise: nil)
    }
}
