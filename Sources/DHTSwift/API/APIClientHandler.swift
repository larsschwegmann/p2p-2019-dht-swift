import Foundation
import NIO

// MARK: - APIClientHandler

final class APIClientHandler: ChannelInboundHandler {
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
