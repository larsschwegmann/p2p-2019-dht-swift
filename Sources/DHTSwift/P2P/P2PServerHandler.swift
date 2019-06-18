import Foundation
import NIO
import UInt256

final class P2PServerHandler: ChannelInboundHandler {
    public typealias InboundIn = NetworkMessage
    public typealias OutboundOut = NetworkMessage

    // MARK: ChannelInboundHandler protocol functions

    public func channelActive(context: ChannelHandlerContext) {
        print("P2PServer: Client connected from \(context.remoteAddress!)")
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let message = unwrapInboundIn(data)
        switch message {
        case let find as P2PPeerFind:
            print("P2PServer: Received Peer Find for key \(find.key)")
            let chord = Chord.shared
            guard let peer = try? chord.closestPeer(identifier: find.key) else {
                print("P2PServer: Could not find closest peer for id \(find.key)")
                context.close(promise: nil)
                return
            }
            let found = P2PPeerFound(key: find.key, ipAddr: peer.getIPv6Bytes()!, port: UInt16(peer.port!))
            print("Found Peer for key \(find.key): \(peer.description)")
            context.writeAndFlush(wrapOutboundOut(found), promise: nil)
        case let notify as P2PPredecessorNotify:
            guard let addr = try? SocketAddress(ipv6Bytes: notify.ipAddr, port: notify.port) else {
                print("P2PServer: Could not decode IPv6 address from bytes: \(notify.ipAddr)")
                context.close(promise: nil)
                return
            }
            print("P2PServer; Received Predecessor Notify with address \(addr)")
            let oldPredecessor = self.notifyPredecessor(predecessorAddress: addr)
            let reply = P2PPredecessorReply(ipAddr: oldPredecessor.getIPv6Bytes()!, port: UInt16(oldPredecessor.port!))
            context.writeAndFlush(wrapOutboundOut(reply), promise: nil)
        case let storageGet as P2PStorageGet:
            handleStorageGet(storageGet: storageGet, context: context)
        case let storagePut as P2PStoragePut:
            handleStoragePut(storagePut: storagePut, context: context)
        default:
            print("P2PServer: Got unexpected message \(message)")
            return
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

    // MARK: Private helper functions

    private func handleStorageGet(storageGet: P2PStorageGet, context: ChannelHandlerContext) {
        let chord = Chord.shared
        let rawKey = storageGet.key
        let replicationIndex = storageGet.replicationIndex
        let key = Identifier.Key(rawKey: rawKey, replicationIndex: replicationIndex)
        let id = Identifier.key(key)

        print("P2PServer: Received STORAGE GET request for key \(key)")

        guard let responsible = try? chord.responsibleFor(identifier: id) else {
            print("P2PServer: Current node not bootstrapped")
            context.close(promise: nil)
            return
        }
        if responsible {
            guard let hashValue = id.hashValue else {
                print("P2PServer: Could not decode address to create hash")
                return
            }
            let valueOpt = chord.keyStore[hashValue]
            guard let value = valueOpt else {
                print("P2PServer: Could not find value for key: \(key)")
                let storageGetFailure = P2PStorageFailure(key: hashValue)
                context.writeAndFlush(wrapOutboundOut(storageGetFailure), promise: nil)
                return
            }
            print("P2PServer: Found value for key \(key) and replying with STORAGE GET SUCCESS")

            let storageGetSuccess = P2PStorageGetSuccess(key: hashValue, value: value)
            context.writeAndFlush(wrapOutboundOut(storageGetSuccess), promise: nil)
        }
    }

    private func handleStoragePut(storagePut: P2PStoragePut, context: ChannelHandlerContext) {
        let chord = Chord.shared
        let rawKey = storagePut.key
        let replicationIndex = storagePut.replicationIndex
        let key = Identifier.Key(rawKey: rawKey, replicationIndex: replicationIndex)
        let id = Identifier.key(key)
        let value = storagePut.value

        print("P2PServer: Received STORAGE PUT request for key \(key)")

        guard let responsible = try? chord.responsibleFor(identifier: id) else {
            print("P2PServer: Current node not bootstrapped")
            context.close(promise: nil)
            return
        }
        if responsible {
            guard let hashedKey = id.hashValue else {
                print("P2PServer: Could not decode address to create hash")
                return
            }
            let valueOpt = chord.keyStore[hashedKey]

            if let _ = valueOpt {
                print("P2PServer: Value for key \(key) already exists, replying with STORAGE PUT FAILURE")
                let storagePutFailure = P2PStorageFailure(key: hashedKey)
                context.writeAndFlush(wrapOutboundOut(storagePutFailure), promise: nil)
                return
            }

            chord.keyStore[hashedKey] = value

            print("P2PServer: Stored value for key \(hashedKey), replying with STORAGE PUT SUCCESS")
            let storageGetSuccess = P2PStorageGetSuccess(key: hashedKey, value: value)
            context.writeAndFlush(wrapOutboundOut(storageGetSuccess), promise: nil)
        }
    }
    
    private func notifyPredecessor(predecessorAddress: SocketAddress) -> SocketAddress {
        let chord = Chord.shared
        let oldPredecessor = chord.predecessor!

        if try! chord.responsibleFor(identifier: Identifier.socketAddress(address: oldPredecessor)) {
            print("P2PServer: Updated predecessor to \(predecessorAddress)")
            chord.predecessor = predecessorAddress
        }

        if chord.predecessor == chord.currentAddress {
            print("P2PServer: Updated predecessor to \(predecessorAddress)")
            chord.predecessor = predecessorAddress
        }

        if chord.successor == chord.currentAddress {
            print("P2PServer: Updated successor to \(predecessorAddress)")
            chord.successor = predecessorAddress
        }
        return oldPredecessor
    }
}


