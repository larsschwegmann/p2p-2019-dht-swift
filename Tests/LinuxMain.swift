import XCTest

import DHTSwiftTests

var tests = [XCTestCaseEntry]()
tests += APIMessageTests.allTests()
tests += P2PMessageTests.allTests()
XCTMain(tests)
