//
//  P2PMessageTests.swift
//  DHTSwiftTests
//
//  Created by Lars Schwegmann on 12.06.19.
//

import XCTest
import Foundation
@testable import DHTSwift

class P2PMessageTests: XCTestCase {

    func testP2PStorageGet() {
        let buf: [UInt8] = [
            // Header
            0, 40, 0x03, 0xe8,
            // Replication and reserved
            4, 0x00, 0x00, 0x00,
            // 32 bytes for key
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
        ]
        let msg = P2PStorageGet(replicationIndex: 4, key: Array<UInt8>(repeating: 3, count: 32))
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(P2PStorageGet.fromBytes(buf), msg)
    }

    func testP2PStoragePut() {
        let buf: [UInt8] = [
            // Header
            0, 45, 0x03, 0xe9,
            // TTL, replication and reserved
            0, 12, 4, 0,
            // 32 bytes for key
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            // value
            1, 2, 3, 4, 5
        ]
        let msg = P2PStoragePut(ttl: 12,
                                replicationIndex: 4,
                                key: Array<UInt8>(repeating: 3, count: 32),
                                value: [1, 2, 3, 4, 5])
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(P2PStoragePut.fromBytes(buf), msg)
    }

    func testP2PStorageGetSuccess() {
        let buf: [UInt8] = [
            // Header
            0, 41, 0x03, 0xea,
            // 32 bytes for key
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            // value
            1, 2, 3, 4, 5
        ]
        let msg = P2PStorageGetSuccess(key: Array<UInt8>(repeating: 3, count: 32), value: [1, 2, 3, 4, 5])
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(P2PStorageGetSuccess.fromBytes(buf), msg)
    }

    func testP2PStoragePutSuccess() {
        let buf: [UInt8] = [
            // Header
            0, 36, 0x03, 0xeb,
            // 32 bytes for key
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
        ]
        let msg = P2PStoragePutSuccess(key: Array<UInt8>(repeating: 3, count: 32))
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(P2PStoragePutSuccess.fromBytes(buf), msg)
    }

    func testP2PStorageFailure() {
        let buf: [UInt8] = [
            // Header
            0, 36, 0x03, 0xec,
            // 32 bytes for key
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
        ]
        let msg = P2PStorageFailure(key: Array<UInt8>(repeating: 3, count: 32))
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(P2PStorageFailure.fromBytes(buf), msg)
    }

    func testP2PPeerFind() {
        let buf: [UInt8] = [
            // Header
            0, 36, 0x04, 0x1a,
            // 32 bytes for identifier
            5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
            5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5
        ]
        let msg = P2PPeerFind(key: Array(repeating: 5, count: 32))
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(P2PPeerFind.fromBytes(buf), msg)
    }

    func testP2PPeerFoundIPv4() {
        let buf: [UInt8] = [
            // Header
            0, 54, 0x04, 0x1b,
            // 32 bytes for identifier
            5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
            5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
            // 16 bytes for ip address
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 127, 0, 0, 1,
            // port
            31, 144
        ]
        let msg = P2PPeerFound(key: Array(repeating: 5, count: 32), ipAddr: Array<UInt8>(ipv4String: "127.0.0.1")!, port: 8080)
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(P2PPeerFound.fromBytes(buf), msg)
    }

    func testP2PPeerFoundIPv6() {
        let buf: [UInt8] = [
            // Header
            0, 54, 0x04, 0x1b,
            // 32 bytes for identifier
            5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
            5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
            // 16 bytes for ip address
            32, 1, 13, 184, 133, 163, 0, 0, 0, 0, 138, 35, 3, 112, 115, 52,
            // port
            31, 144
        ]
        let msg = P2PPeerFound(key: Array(repeating: 5, count: 32), ipAddr: Array<UInt8>(ipv6String: "2001:0db8:85a3:0000:0000:8a23:0370:7334")!, port: 8080)
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(P2PPeerFound.fromBytes(buf), msg)
    }

    func testP2PPredecessorNotifyIPv4() {
        let buf: [UInt8] = [
            // Header
            0, 22, 0x04, 0x1c,
            // 16 bytes for ip address
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 127, 0, 0, 1,
            // port
            31, 144
        ]
        let msg = P2PPredecessorNotify(ipAddr: Array<UInt8>(ipv4String: "127.0.0.1")!, port: 8080)
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(P2PPredecessorNotify.fromBytes(buf), msg)
    }

    func testP2PPredecessorNotifyIPv6() {
        let buf: [UInt8] = [
            // Header
            0, 22, 0x04, 0x1c,
            // 16 bytes for ip address
            32, 1, 13, 184, 133, 163, 0, 0, 0, 0, 138, 35, 3, 112, 115, 52,
            // port
            31, 144
        ]
        let msg = P2PPredecessorNotify(ipAddr: Array<UInt8>(ipv6String: "2001:0db8:85a3:0000:0000:8a23:0370:7334")!, port: 8080)
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(P2PPredecessorNotify.fromBytes(buf), msg)
    }

    func testP2PPredecessorReplyIPv4() {
        let buf: [UInt8] = [
            // Header
            0, 22, 0x04, 0x1d,
            // 16 bytes for ip address
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 127, 0, 0, 1,
            // port
            31, 144
        ]
        let msg = P2PPredecessorReply(ipAddr: Array<UInt8>(ipv4String: "127.0.0.1")!, port: 8080)
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(P2PPredecessorReply.fromBytes(buf), msg)
    }

    func testP2PPredecessorReplyIPv6() {
        let buf: [UInt8] = [
            // Header
            0, 22, 0x04, 0x1d,
            // 16 bytes for ip address
            32, 1, 13, 184, 133, 163, 0, 0, 0, 0, 138, 35, 3, 112, 115, 52,
            // port
            31, 144
        ]
        let msg = P2PPredecessorReply(ipAddr: Array<UInt8>(ipv6String: "2001:0db8:85a3:0000:0000:8a23:0370:7334")!, port: 8080)
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(P2PPredecessorReply.fromBytes(buf), msg)
    }

    static var allTests = [
        ("testP2PStorageGet", testP2PStorageGet),
        ("testP2PStoragePut", testP2PStoragePut),
        ("testP2PStorageGetSuccess", testP2PStorageGetSuccess),
        ("testP2PStoragePutSuccess", testP2PStoragePutSuccess),
        ("testP2PStorageFailure", testP2PStorageFailure),
        ("testP2PPeerFind", testP2PPeerFind),
        ("testP2PPeerFoundIPv4", testP2PPeerFoundIPv4),
        ("testP2PPeerFoundIPv6", testP2PPeerFoundIPv6),
        ("testP2PPredecessorNotifyIPv4", testP2PPredecessorNotifyIPv4),
        ("testP2PPredecessorNotifyIPv6", testP2PPredecessorNotifyIPv6),
        ("testP2PPredecessorReplyIPv4", testP2PPredecessorReplyIPv4),
        ("testP2PPredecessorReplyIPv6", testP2PPredecessorReplyIPv6)
    ]
}
