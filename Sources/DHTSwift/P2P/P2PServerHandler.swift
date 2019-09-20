import Foundation
import Logging
import NIO
import UInt256

final class P2PServerHandler: ChannelInboundHandler {
    public typealias InboundIn = NetworkMessage
    public typealias OutboundOut = NetworkMessage

    private let chord: Chord

    private let logger = Logger(label: "P2PServerHandler")

    init(chord: Chord) {
        self.chord = chord
    }

    // MARK: ChannelInboundHandler protocol functions

    public func channelActive(context: ChannelHandlerContext) {
        //logger.info("Client connected from \(context.remoteAddress!)")
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let message = unwrapInboundIn(data)
        switch message {
        case let find as P2PPeerFind:
            logger.info("Received Peer Find for key \(find.key)")
            guard let peer = try? chord.closestPeer(identifier: find.key) else {
                logger.error("Could not find closest peer for id \(find.key)")
                context.close(promise: nil)
                return
            }
            let found = P2PPeerFound(key: find.key, ipAddr: peer.getIPv6Bytes()!, port: UInt16(peer.port!))
            logger.info("Found Peer for key \(find.key): \(peer.description)")
            context.writeAndFlush(wrapOutboundOut(found), promise: nil)
        case let notify as P2PPredecessorNotify:
            guard let addr = try? SocketAddress(ipv6Bytes: notify.ipAddr, port: notify.port) else {
                logger.error("Could not decode IPv6 address from bytes: \(notify.ipAddr)")
                context.close(promise: nil)
                return
            }
            logger.info("Received Predecessor Notify with address \(addr)")
            let oldPredecessor = self.notifyPredecessor(predecessorAddress: addr)
            let reply = P2PPredecessorReply(ipAddr: oldPredecessor.getIPv6Bytes()!, port: UInt16(oldPredecessor.port!))
            context.writeAndFlush(wrapOutboundOut(reply), promise: nil)
        case let storageGet as P2PStorageGet:
            handleStorageGet(storageGet: storageGet, context: context)
        case let storagePut as P2PStoragePut:
            handleStoragePut(storagePut: storagePut, context: context)
        case _ as P2PSuccessorRequest:
            var successors = [SocketAddress]()
            if let predecessorAddr = chord.predecessor.value {
                successors.append(predecessorAddr)
            }
            successors.append(chord.currentAddress)
            successors.append(contentsOf: chord.successors.value)
            let reply = P2PSuccessorReply(successors: successors)
            context.writeAndFlush(wrapOutboundOut(reply), promise: nil)
        default:
            logger.error("Got unexpected message \(message)")
            context.close(promise: nil)
        }
    }

    // Flush it out. This can make use of gathering writes if multiple buffers are pending
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    func channelUnregistered(context: ChannelHandlerContext) {
        //logger.info("Connection to client at \(context.remoteAddress!) closed")
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("Unexpected error: \(error)")

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }

    // MARK: Private helper functions

    private func handleStorageGet(storageGet: P2PStorageGet, context: ChannelHandlerContext) {
        let rawKey = storageGet.key
        let replicationIndex = storageGet.replicationIndex
        let key = Identifier.Key(rawKey: rawKey, replicationIndex: replicationIndex)
        let id = Identifier.key(key)

        logger.info("Received STORAGE GET request for key \(key)")

        guard let responsible = try? chord.responsibleFor(identifier: id) else {
            logger.error("Current node not bootstrapped")
            context.close(promise: nil)
            return
        }
        if responsible {
            guard let hashValue = id.hashValue else {
                logger.error("Could not decode address to create hash")
                return
            }
            let valueOpt = chord.keyStore.value[hashValue]
            guard let value = valueOpt else {
                logger.warning("Could not find value for key: \(key)")
                let storageGetFailure = P2PStorageFailure(key: hashValue)
                context.writeAndFlush(wrapOutboundOut(storageGetFailure), promise: nil)
                return
            }
            logger.info("Found value for key \(key) and replying with STORAGE GET SUCCESS")

            let storageGetSuccess = P2PStorageGetSuccess(key: hashValue, value: value)
            context.writeAndFlush(wrapOutboundOut(storageGetSuccess), promise: nil)
        }
    }

    private func handleStoragePut(storagePut: P2PStoragePut, context: ChannelHandlerContext) {
        let rawKey = storagePut.key
        let replicationIndex = storagePut.replicationIndex
        let key = Identifier.Key(rawKey: rawKey, replicationIndex: replicationIndex)
        let id = Identifier.key(key)
        let value = storagePut.value

        logger.info("Received STORAGE PUT request for key \(key)")

        guard let responsible = try? chord.responsibleFor(identifier: id) else {
            logger.error("Current node not bootstrapped")
            context.close(promise: nil)
            return
        }
        if responsible {
            guard let hashedKey = id.hashValue else {
                logger.error("Could not decode address to create hash")
                return
            }
            let valueOpt = chord.keyStore.value[hashedKey]

            if let _ = valueOpt {
                logger.info("Value for key \(key) already exists, replying with STORAGE PUT FAILURE")
                let storagePutFailure = P2PStorageFailure(key: hashedKey)
                context.writeAndFlush(wrapOutboundOut(storagePutFailure), promise: nil)
                return
            }

            chord.keyStore.mutate { $0[hashedKey] = value }

            logger.info("Stored value for key \(hashedKey), replying with STORAGE PUT SUCCESS")
            let storageGetSuccess = P2PStoragePutSuccess(key: rawKey)
            context.writeAndFlush(wrapOutboundOut(storageGetSuccess), promise: nil)
        }
    }
    
    private func notifyPredecessor(predecessorAddress: SocketAddress) -> SocketAddress {
        let oldPredecessor = chord.predecessor.value!

        if try! chord.responsibleFor(identifier: Identifier.socketAddress(address: predecessorAddress)) {
            chord.predecessor.mutate { $0 = predecessorAddress }
            logger.info("PredecessorNotify: Updated predecessor to \(predecessorAddress)")
        }

        if chord.predecessor.value == chord.currentAddress {
            chord.predecessor.mutate { $0 = predecessorAddress }
            logger.info("PredecessorNotify: Updated predecessor to \(predecessorAddress)")
        }

//        if chord.successors.value[0] == chord.currentAddress && predecessorAddress != chord.currentAddress {
//            logger.info("PredecessorNotify: Updated successor to \(predecessorAddress)")
//            chord.setSuccessor(successorAddr: predecessorAddress)
//        }
        return oldPredecessor
    }
}


