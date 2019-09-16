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
        self.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: TimeAmount.seconds(0), delay: TimeAmount.hours(1)) { [weak self] _ in
            self?.stabilize()
        }
    }

    private func stabilize() {
        logger.info("Running Stabilization...")
        guard let updateSuccessorFuture = updateSuccessor(),
            let updateFingerFuture = updateFingers() else {
                return
        }

        let loop = self.eventLoopGroup.next()
        let combined = [updateSuccessorFuture, updateFingerFuture].flatten(on: loop)
        combined.whenSuccess { [weak self] _ in
            self?.logger.info("Stabilization successful!")
        }

        combined.whenFailure { [weak self] (err) in
            self?.logger.error("Stabilization error: \(err)")
        }

    }

    private func updateSuccessor() -> EventLoopFuture<Void>? {
        logger.info("Upating successor...")

        let current = chord.currentAddress
        guard let successor = chord.successor else {
            return nil
        }

        logger.info("Calling NOTIFY PREDECESSOR on \(successor)")

        return chord.notifyPredecessor(address: current, peerAddress: successor).map { newSuccessor in
            let currentId = Identifier.socketAddress(address: current)
            let successorId = Identifier.socketAddress(address: successor)
            let newSuccessorId = Identifier.socketAddress(address: newSuccessor)

            if newSuccessorId.isBetween(lhs: currentId, rhs: successorId) {
                self.logger.info("Updating successor to address \(newSuccessor)")
                self.chord.successor = newSuccessor
            }
            return ()
        }
    }

    private func updateFingers() -> EventLoopFuture<Void>? {
        let current = chord.currentAddress
        let fingers = chord.fingerTable
        guard let successor = chord.successor else {
            return nil
        }

        logger.info("Updating finger table using our successor \(successor)")

        let loop = self.eventLoopGroup.next()

        return fingers.value.map { (key, value) -> EventLoopFuture<Void> in
            // TODO: Fix this, identifier is always the same value for some reason
            let shiftedKey = UInt256(UInt256(1) << UInt256(UInt256(255) - UInt256(key)))
            let identifier = Identifier.socketAddress(address: current) + Identifier.existingHash(shiftedKey)
            return chord.findPeer(forIdentifier: identifier, peerAddress: successor).map({ peerAddress in
                self.chord.fingerTable.mutate { $0[key] = peerAddress }
            })
        }.flatten(on: loop)
    }
}
