//
//  P2PMessage.swift
//  DHTSwift
//
//  Created by Lars Schwegmann on 12.06.19.
//

import Foundation

// MARK: P2PStorageGet

struct P2PStorageGet: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }

    
}

// MARK: P2PStoragePut

struct P2PStoragePut: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }


}

// MARK: P2PStorageGetSuccess

struct P2PStorageGetSuccess: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }


}

// MARK: P2PStoragePutSuccess

struct P2PStoragePutSuccess: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }


}

// MARK: P2PStorageFailure

struct P2PStorageFailure: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }


}

// MARK: P2PPeerFind

struct P2PPeerFind: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }


}

// MARK: P2PPeerFound

struct P2PPeerFound: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }


}

// MARK: P2PPredecessorNotify

struct P2PPredecessorNotify: NetworkMessage, Equatable {
    static var messageTypeID: UInt16

    var serializedBody: [UInt8]

    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }


}

// MARK: P2PPRedecessorReply

struct P2PPredecessorReply: NetworkMessage, Equatable {
    static var messageTypeID: UInt16
    
    var serializedBody: [UInt8]
    
    init?(serializedBodyBytes: [UInt8]) {
        <#code#>
    }
    

}
