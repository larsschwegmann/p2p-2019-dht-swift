import Foundation
import NIO

/// Encodes a NetworkMessage into a ByteBuffer
struct NetworkMessageToByteEncoder: MessageToByteEncoder {
    typealias OutboundIn = NetworkMessage

    func encode(data: NetworkMessage, out: inout ByteBuffer) throws {
        let bytes = data.getBytes()
        out.writeBytes(bytes)
    }
}
