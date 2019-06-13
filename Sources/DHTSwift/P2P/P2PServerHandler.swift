import Foundation
import NIO
import UInt256

final class P2PServerHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    // MARK: ChannelInboundHandler protocol functions

    public func channelActive(context: ChannelHandlerContext) {
        print("P2PServer: Client connected from \(context.remoteAddress!)")
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
            print("P2PServer: Got DHT GET request for key \(message.key)")
            guard let value = dummyDict[message.key] else {
                print("P2PServer: Could not find value for key \(message.key)")
                self.sendFailure(key: message.key, context: context)
                return
            }

            let success = DHTSuccess(key: message.key, value: value)
            let successBytes = success.getBytes()
            var writeBuffer = context.channel.allocator.buffer(capacity: successBytes.count)
            writeBuffer.writeBytes(successBytes)
            print("P2PServer: Sent DHTSuccess \(success) for key \(message.key)")
            context.write(wrapOutboundOut(writeBuffer), promise: nil)
        } else if let message = DHTPut.fromBytes(bytes) {
            // DHT PUT Request
            print("P2PServer: GOT DHT PUT request for key \(message.key), value \(message.value)")
            dummyDict[message.key] = message.value
            context.close(promise: nil)
        }
    }

    // Flush it out. This can make use of gathering writes if multiple buffers are pending
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    func channelUnregistered(context: ChannelHandlerContext) {
        print("P2PServer: Connection to client at \(context.remoteAddress!) closed")
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("P2PServer: Unexpected error: ", error)

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }

    // MARK: Private functions

    private func sendFailure(key: UInt256, context: ChannelHandlerContext) {
        let failure = DHTFailure(key: key)
        let failureBytes = failure.getBytes()
        var writeBuffer = context.channel.allocator.buffer(capacity: failureBytes.count)
        writeBuffer.writeBytes(failureBytes)
        context.write(wrapOutboundOut(writeBuffer), promise: nil)
        print("P2PServer: Sent failure \(failure) for key \(key)")
    }
}

