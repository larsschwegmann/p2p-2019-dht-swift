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
        var count = 0
        self.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: TimeAmount.seconds(30), delay: TimeAmount.seconds(30)) { [weak self] _ in
            if count < 1 {
                self?.stabilize()
                count += 1
            }
        }
    }

    private func stabilize() {
        logger.info("Running Stabilization...")

        let combined = updateSuccessor()!.flatMap { [weak self] _ -> EventLoopFuture<Void> in
            return self!.updateFingers()!
        }

        combined.whenSuccess { [weak self] _ in
            self?.logger.info("Stabilization successful! Successor: \(self?.chord.successor.value?.description ?? "nil"), Predecessor: \(self?.chord.predecessor.value?.description ?? "nil")")
        }

        combined.whenFailure { [weak self] err in
            self?.logger.error("Stabilization error: \(err)")
        }
    }

    private func updateSuccessor() -> EventLoopFuture<Void>? {
        logger.info("Updating successor...")

        let current = chord.currentAddress
        guard let successor = chord.successor.value else {
            return nil
        }

        logger.info("Calling NOTIFY PREDECESSOR on \(successor)")

        return chord.notifyPredecessor(address: current, peerAddress: successor).map { newSuccessor in
            let currentId = Identifier.socketAddress(address: current)
            let successorId = Identifier.socketAddress(address: successor)
            let newSuccessorId = Identifier.socketAddress(address: newSuccessor)

            if newSuccessorId.isBetween(lhs: currentId, rhs: successorId) {
                self.logger.info("Updating successor to address \(newSuccessor)")
                self.chord.setSuccessor(successorAddr: newSuccessor)
            }
            return ()
        }
    }

    private func updateFingers() -> EventLoopFuture<Void>? {
        let current = chord.currentAddress
        let fingers = chord.fingerTable
        guard let successor = chord.successor.value else {
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
