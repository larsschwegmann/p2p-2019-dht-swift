import Foundation
import Logging
import NIO

// MARK: - APIClientHandler
/// An `APIClientHandler` is used to handle requests for key lookups from the APIClient.
/// The responses are either a DHT success or failure.
final class APIClientHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    let requestPayload: [UInt8]

    private var numBytes = 0
    private let logger = Logger(label: "APIClientHandler")

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
        logger.info("Sent message to server: \(requestPayload)")
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        let readableBytes = buffer.readableBytes

        guard let message = buffer.readBytes(length: readableBytes) else {
            logger.error("Could not read bytes")
            return
        }

        if let dhtSuccess = DHTSuccess.fromBytes(message) {
            logger.info("Found value \(dhtSuccess.value) for key \(dhtSuccess.key)")
        } else if let dhtFailure = DHTFailure.fromBytes(message) {
            logger.error("Could not find value for key \(dhtFailure.key)")
        }

        if numBytes == 0 {
            logger.info("nothing left to read, close the channel")
            context.close(promise: nil)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("\(error.localizedDescription)")
        context.close(promise: nil)
    }
}
