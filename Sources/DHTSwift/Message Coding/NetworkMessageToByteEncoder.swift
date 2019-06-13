import Foundation
import NIO

struct NetworkMessageToByteEncoder: MessageToByteEncoder {
    typealias OutboundIn = NetworkMessage

    func encode(data: NetworkMessage, out: inout ByteBuffer) throws {
        let bytes = data.getBytes()
        out.writeBytes(bytes)
    }
}
