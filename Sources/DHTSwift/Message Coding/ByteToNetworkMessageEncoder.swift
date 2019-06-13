import Foundation
import NIO

/// Decodes a ByteBuffer to a NetworkMessage object
public struct ByteToNetworkMessageDecoder: ByteToMessageDecoder {
    public typealias InboundOut = NetworkMessage

    public mutating func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        guard buffer.readableBytes >= 2,
            let sizeBytes = buffer.getBytes(at: buffer.readerIndex, length: 2) else {
            // The first 2 bytes of the message indicate the size
            return .needMoreData
        }

        let size = sizeBytes.withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
        guard buffer.readableBytes >= size else {
            // We can't read the whole message yet
            return .needMoreData
        }

        guard let structBytes = buffer.readBytes(length: Int(size)) else {
            // This is technically impossible
            return .needMoreData
        }

        let messageTypeIDRaw = structBytes[2...3].withUnsafeBytes({ $0.load(as: UInt16.self) }).byteSwapped
        guard let messageTypeID = NetworkMessageTypeID.init(rawValue: messageTypeIDRaw) else {
            // Error or unknown message type id
            return .continue
        }

        let networkMessage: NetworkMessage? = messageTypeID.getType().fromBytes(structBytes)

        if networkMessage != nil {
            context.fireChannelRead(wrapInboundOut(networkMessage!))
        }

        return .continue
    }

    public mutating func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
        return .continue
    }



}
