import XCTest

import dht_moduleTests

var tests = [XCTestCaseEntry]()
tests += dht_moduleTests.allTests()
XCTMain(tests)
