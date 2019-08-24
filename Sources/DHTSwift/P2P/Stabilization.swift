import Foundation
import NIO
import AsyncKit
import UInt256

// MARK: Stabilization

public final class Stabilization {

    private let eventLoopGroup: EventLoopGroup
    private let config: Configuration
    private let chord: Chord

    init(eventLoopGroup: EventLoopGroup, config: Configuration, chord: Chord) {
        self.eventLoopGroup = eventLoopGroup
        self.config = config
        self.chord = chord
    }

    func start() {
        self.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: TimeAmount.seconds(0), delay: TimeAmount.seconds(TimeAmount.Value(config.stabilizationInterval))) { [weak self] _ in
            self?.stabilize()
        }
    }

    private func stabilize() {
        guard let updateSuccessorFuture = updateSuccessor(),
            let updateFingerFuture = updateFingers() else {
                return
        }

        let loop = self.eventLoopGroup.next()
        let combined = [updateSuccessorFuture, updateFingerFuture].flatten(on: loop)
        combined.whenSuccess { _ in
            print("Stabilization successful!")
        }

        combined.whenFailure { (err) in
            print("Stabilization error: \(err)")
        }

    }

    private func updateSuccessor() -> EventLoopFuture<Void>? {
        let current = chord.currentAddress
        guard let successor = chord.successor else {
            return nil
        }

        return chord.notifyPredecessor(address: current, peerAddress: successor).map { newSuccessor in
            let currentId = Identifier.socketAddress(address: current)
            let successorId = Identifier.socketAddress(address: successor)
            let newSuccessorId = Identifier.socketAddress(address: newSuccessor)

            if newSuccessorId.isBetween(lhs: currentId, rhs: successorId) {
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

        let loop = self.eventLoopGroup.next()

        return fingers.map { (key, value) -> EventLoopFuture<Void> in
            let identifier = Identifier.socketAddress(address: current) + Identifier.existingHash(UInt256(0x1 << (255 - key)))
            return chord.findPeer(forIdentifier: identifier, peerAddress: successor).map({ peerAddress in
                self.chord.fingerTable[key] = peerAddress
            })
        }.flatten(on: loop)
    }
}
