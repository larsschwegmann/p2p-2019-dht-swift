import Foundation
import Logging
import NIO
import AsyncKit
import UInt256

// MARK: Stabilization

public final class Stabilization {

    private let eventLoopGroup: EventLoopGroup
    private let config: Configuration
    private let chord: Chord

    private let logger = Logger(label: "Stabilization")

    init(eventLoopGroup: EventLoopGroup, config: Configuration, chord: Chord) {
        self.eventLoopGroup = eventLoopGroup
        self.config = config
        self.chord = chord
    }

    func start() {
        self.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: TimeAmount.seconds(10), delay: TimeAmount.seconds(Int64(self.config.stabilizationInterval))) { [weak self] _ in
            self?.stabilize()
        }
    }

    /// Called every stabilization_interval seconds
    private func stabilize() {
        logger.info("Running Stabilization...")

        let combined = updateSuccessors()!.flatMap { [weak self] _ -> EventLoopFuture<Void> in
            return self!.updateFingers()!
        }

        combined.whenSuccess { [weak self] _ in
            self?.logger.info("Stabilization successful! Successors: \(self?.chord.successors.value.map { $0.description }.description ?? "nil"), Predecessor: \(self?.chord.predecessor.value?.description ?? "nil")")
        }

        combined.whenFailure { [weak self] err in
            self?.logger.error("Stabilization error: \(err)")
        }
    }

    /// Retrieves our successor's successor list and updates our own
    private func updateSuccessors() -> EventLoopFuture<Void>? {
        logger.info("Updating successors...")

        let current = chord.currentAddress
        guard let successor = chord.successors.value[safe: 0] else {
            return nil
        }

        let successorFutures = chord.successors.value.map { succ -> EventLoopFuture<Result<[SocketAddress], ChordError>> in
            return chord.getSuccessors(peerAddress: succ)
        }

        let futuresFlattened = EventLoopFuture.whenAllComplete(successorFutures, on: self.eventLoopGroup.next()).flatMapThrowing { results -> [SocketAddress] in
            var blacklist = Set<SocketAddress>()
            var successors = results.flatMap({ [weak self] result -> [SocketAddress] in
                switch result {
                case .success(let nested):
                    switch nested {
                    case .success(let successorAddresses):
                        return successorAddresses
                    case .failure(let reason):
                        if case ChordError.deadPeer(let peerAddress) = reason {
                            blacklist.insert(peerAddress)
                        }
                        return []
                    }
                case .failure(let error):
                    self?.logger.error("Error while trying to request successors: \(error)")
                    return []
                }
            })
            successors = successors.filter { !blacklist.contains($0) }

            self.chord.setSuccessors(successorAddr: successors.uniques)
            return successors
        }.flatMap { successors -> EventLoopFuture<Void> in
            self.logger.info("Calling NOTIFY PREDECESSOR on \(successor)")
            return self.chord.notifyPredecessor(address: current, peerAddress: successors[0]).transform(to: ())
        }

        return futuresFlattened
    }

    /// Updates our finger table by asking our successor
    private func updateFingers() -> EventLoopFuture<Void>? {
        let current = chord.currentAddress
        let fingers = chord.fingerTable
        guard let successor = chord.successors.value[safe: 0] else {
            return nil
        }

        logger.info("Updating finger table using our successor \(successor)")

        let loop = self.eventLoopGroup.next()

        // TODO: Make this respect the order of the fingertable, one after the other
        return fingers.value.map { (key, value) -> EventLoopFuture<Void> in
            let shiftedKey = UInt256(UInt256(1) << UInt256(UInt256(255) - UInt256(key)))
            let identifier = Identifier.socketAddress(address: current) + Identifier.existingHash(shiftedKey)
            return chord.findPeer(forIdentifier: identifier, peerAddress: successor).map({ peerAddress in
                self.chord.fingerTable.mutate { $0[key] = peerAddress }
            })
        }.flatten(on: loop)
    }
}
