import Foundation
import UInt256

class KeyStore {

    // MARK: Properties

    private var storage = [UInt256: [UInt8]]()

    // MARK: Initializers

    convenience init(_ existingKeyValuePairs: [UInt256: [UInt8]]) {
        self.init()
        self.storage = existingKeyValuePairs
    }

    func put(key: UInt256, value: [UInt8]) {
        
    }
}

