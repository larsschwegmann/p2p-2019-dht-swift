import Foundation
import NIO
import UInt256

final class APIServerHandler: ChannelInboundHandler {
    public typealias InboundIn = NetworkMessage
    public typealias OutboundOut = NetworkMessage

    // MARK: ChannelInboundHandler protocol functions

    public func channelActive(context: ChannelHandlerContext) {
        print("APIServer: Client connected from \(context.remoteAddress!)")
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let message = unwrapInboundIn(data)

        switch message {
        case let get as DHTGet:
            // DHT GET Request
            print("APIServer: Got DHT GET request for key \(get.key)")
            guard let value = dummyDict[get.key] else {
                print("APIServer: Could not find value for key \(get.key)")
                let failure = DHTFailure(key: get.key)
                context.write(wrapOutboundOut(failure), promise: nil)
                return
            }

            let success = DHTSuccess(key: get.key, value: value)
            print("APIServer: Sent DHTSuccess \(success) for key \(get.key)")
            context.writeAndFlush(wrapOutboundOut(success), promise: nil)
        case let put as DHTPut:
            print("APIServer: Got DHT PUT request with key \(put.key) value \(put.value)")
            dummyDict[put.key] = put.value
            print("APIServer: Did PUT with key \(put.key) value \(put.value)")
            context.close(promise: nil)
        default:
            return
        }
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
}
