import XCTest
import Foundation
@testable import DHTSwift

class APIMessageTests: XCTestCase {

    func testAPIDHTPut() {
        let buf: [UInt8] = [
            // Header
            0, 45, 0x02, 0x8a,
            // TTL, replication and reserved
            0, 12, 4, 0,
            // 32 bytes for key
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            // value
            1, 2, 3, 4, 5,
        ]
        let msg = DHTPut(ttl: 12,
                         replication: 4,
                         key: Array<UInt8>(repeating: 3, count: 32),
                         value: [1, 2, 3, 4, 5])
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(DHTPut.fromBytes(buf), msg)
    }

    func testAPIDHTGet() {
        let buf: [UInt8] = [
            // Header
            0, 36, 0x02, 0x8b,
            // 32 bytes for key
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
        ]
        let msg = DHTGet(key: Array<UInt8>(repeating: 3, count: 32))
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(DHTGet.fromBytes(buf), msg)
    }

    func testAPIDHTSuccess() {
        let buf: [UInt8] = [
            // Header
            0, 41, 0x02, 0x8c,
            // 32 bytes for key
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            // value
            1, 2, 3, 4, 5
        ]
        let msg = DHTSuccess(key: Array<UInt8>(repeating: 3, count: 32), value: [1, 2, 3, 4, 5])
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(DHTSuccess.fromBytes(buf), msg)
    }

    func testAPIDHTFailure() {
        let buf: [UInt8] = [
            // Header
            0, 36, 0x02, 0x8d,
            // 32 bytes for key
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
        ]
        let msg = DHTFailure(key: Array<UInt8>(repeating: 3, count: 32))
        XCTAssertEqual(buf, msg.getBytes())
        XCTAssertEqual(DHTFailure.fromBytes(buf), msg)
    }

    static var allTests = [
        ("testAPIDHTPut", testAPIDHTPut),
        ("testAPIDHTGet", testAPIDHTGet),
        ("testAPIDHTSuccess", testAPIDHTSuccess),
        ("testAPIDHTFailure", testAPIDHTFailure)
    ]
}
