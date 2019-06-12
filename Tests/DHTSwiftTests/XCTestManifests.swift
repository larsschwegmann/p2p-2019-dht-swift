import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(APIMessageTests.allTests),
        testCase(P2PMessageTests.allTests)
    ]
}
#endif
